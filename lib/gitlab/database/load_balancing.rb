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

      mattr_accessor :base_models
      mattr_accessor :all_database_names
      mattr_accessor :default_pool_size
      mattr_accessor :enabled, default: true

      def self.configure!
        yield(self)
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

        db_config = db_config_for_connection(connection)
        return ROLE_UNKNOWN unless db_config

        if db_config.name.ends_with?(LoadBalancer::REPLICA_SUFFIX)
          ROLE_REPLICA
        else
          ROLE_PRIMARY
        end
      end

      def self.db_config_for_connection(connection)
        return unless connection

        # For a ConnectionProxy we want to avoid ambiguous db_config as it may
        # sometimes default to replica so we always return the primary config
        # instead.
        if connection.is_a?(::Gitlab::Database::LoadBalancing::ConnectionProxy)
          return connection.load_balancer.configuration.db_config
        end

        # During application init we might receive `NullPool`
        return unless connection.respond_to?(:pool) &&
          connection.pool.respond_to?(:db_config)

        db_config = connection.pool.db_config
        db_config unless empty_config?(db_config)
      end

      def self.empty_config?(db_config)
        return true unless db_config

        db_config.is_a?(ActiveRecord::ConnectionAdapters::NullPool::NullConfig)
      end
    end
  end
end
