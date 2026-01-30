# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # The exceptions raised for connection errors.
      CONNECTION_ERRORS = [
        PG::ConnectionBad,
        PG::ConnectionDoesNotExist,
        PG::ConnectionException,
        PG::ConnectionFailure,
        PG::UnableToSend,
        # During a failover this error may be raised when
        # writing to a primary.
        PG::ReadOnlySqlTransaction,
        # This error is raised when we can't connect to the database in the
        # first place (e.g. it's offline or the hostname is incorrect).
        ActiveRecord::ConnectionNotEstablished
      ].freeze

      def self.base_models
        @base_models ||= ::Gitlab::Database.database_base_models_using_load_balancing.values.freeze
      end

      def self.each_load_balancer
        return to_enum(__method__) unless block_given?

        base_models.each do |model|
          yield model.load_balancer
        end
      end

      def self.primary_only?
        each_load_balancer.all?(&:primary_only?)
      end

      def self.primary?(name)
        each_load_balancer.find { |c| c.name == name }&.primary_only?
      end

      def self.release_hosts
        each_load_balancer(&:release_host)
      end

      DB_ROLES = [
        ROLE_PRIMARY = :primary,
        ROLE_REPLICA = :replica,
        ROLE_UNKNOWN = :unknown
      ].freeze

      # Returns the role (primary/replica) of the database the connection is
      # connecting to.
      def self.db_role_for_connection(connection)
        return ROLE_UNKNOWN if connection.is_a?(::Gitlab::Database::LoadBalancing::ConnectionProxy)

        db_config = Database.db_config_for_connection(connection)
        return ROLE_UNKNOWN unless db_config

        if db_config.name.ends_with?(LoadBalancer::REPLICA_SUFFIX)
          ROLE_REPLICA
        else
          ROLE_PRIMARY
        end
      end
    end
  end
end
