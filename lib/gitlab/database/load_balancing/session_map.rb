# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SessionMap
        CACHE_KEY = :gitlab_load_balancer_session_map

        InvalidLoadBalancerNameError = Class.new(StandardError)

        # lb - Gitlab::Database::LoadBalancing::LoadBalancer instance
        def self.current(load_balancer)
          cached_instance.lookup(load_balancer)
        end

        # models - Array<ActiveRecord::Base>
        def self.with_sessions(models)
          dbs = models.map { |m| m.load_balancer.name }.uniq
          dbs.each { |db| cached_instance.validate_db_name(db) }
          ScopedSessions.new(dbs, cached_instance.session_map)
        end

        def self.clear_session
          RequestStore.delete(CACHE_KEY)
        end

        def self.without_sticky_writes(&)
          with_sessions(Gitlab::Database::LoadBalancing.base_models).ignore_writes(&)
        end

        def self.cached_instance
          RequestStore[CACHE_KEY] ||= new
        end
        private_class_method :cached_instance

        attr_reader :session_map

        def initialize
          @session_map = Gitlab::Database.all_database_names.to_h do |k|
            [k.to_sym, Gitlab::Database::LoadBalancing::Session.new]
          end

          @session_map[:primary] = Gitlab::Database::LoadBalancing::Session.new
        end

        def lookup(load_balancer)
          name = load_balancer.name
          validate_db_name(name)
          session_map[name]
        end

        def validate_db_name(db)
          # Allow :primary only for rake task db migrations as ActiveRecord::Tasks::PostgresqlDatabaseTasks calls
          # .establish_connection using a hash which resets the name from :main/:ci to :primary.
          # See
          # https://github.com/rails/rails/blob/v7.0.8.4/activerecord/lib/active_record/tasks/postgresql_database_tasks.rb#L97
          #
          # In the case of derailed test in memory-on-boot job, the runtime is unknown.
          return if db == :primary && (Gitlab::Runtime.rake? || Gitlab::Runtime.safe_identify.nil?)

          # Disallow :primary usage outside of rake or unknown runtimes as the db config should be
          # main/ci/embedding/ci/geo.
          return if db != :primary && session_map[db]

          raise InvalidLoadBalancerNameError, "Invalid load balancer name #{db} in #{Gitlab::Runtime.safe_identify}."
        end
      end

      class ScopedSessions
        attr_reader :scoped_sessions

        def initialize(scope, session_map)
          @scope = scope
          @scoped_sessions = session_map.slice(*@scope).values
        end

        def use_primary!
          scoped_sessions.each(&:use_primary!)
        end

        def ignore_writes(&)
          nest_sessions(scoped_sessions, :without_sticky_writes, &)
        end

        def use_primary(&)
          nest_sessions(scoped_sessions, :use_primary, &)
        end

        def use_replicas_for_read_queries(&)
          nest_sessions(scoped_sessions, :use_replicas_for_read_queries, &)
        end

        def fallback_to_replicas_for_ambiguous_queries(&)
          nest_sessions(scoped_sessions, :fallback_to_replicas_for_ambiguous_queries, &)
        end

        private

        def nest_sessions(sessions, method, &block)
          if sessions.empty?
            yield if block
          else
            session = sessions.shift
            session.public_send(method) do # rubocop: disable GitlabSecurity/PublicSend -- methods are verified
              nest_sessions(sessions, method, &block)
            end
          end
        end
      end
    end
  end
end
