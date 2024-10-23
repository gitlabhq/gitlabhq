# frozen_string_literal: true

module Gitlab
  module Database
    # This abstract class is used for models which need to exist in multiple de-composed databases.
    class SharedModel < ActiveRecord::Base
      include IgnorableColumns

      self.abstract_class = true

      # if shared model is used, this allows to limit connections
      # on which this model is being shared
      class_attribute :limit_connection_names, default: nil

      class << self
        def using_connection(connection)
          previous_connection = self.overriding_connection

          unless previous_connection.nil? || previous_connection.equal?(connection)
            raise "Cannot change connection for Gitlab::Database::SharedModel "\
              "from '#{Gitlab::Database.db_config_name(previous_connection)}' "\
              "to '#{Gitlab::Database.db_config_name(connection)}'"
          end

          # connection might not be yet adopted (returning nil, and no gitlab_schemas)
          # in such cases it is fine to ignore such connections
          gitlab_schemas = Gitlab::Database.gitlab_schemas_for_connection(connection)

          unless gitlab_schemas.nil? || gitlab_schemas.include?(:gitlab_shared)
            raise "Cannot set `SharedModel` to connection from `#{Gitlab::Database.db_config_name(connection)}` " \
              "since this connection does not include `:gitlab_shared` schema."
          end

          self.overriding_connection = connection

          yield
        ensure
          self.overriding_connection = previous_connection
        end

        def connection
          if connection = self.overriding_connection
            connection
          else
            super
          end
        end

        # in case the connection has been switched with using_connection
        def connection_pool
          connection.pool
        end

        private

        def overriding_connection
          Thread.current[:overriding_connection]
        end

        def overriding_connection=(connection)
          Thread.current[:overriding_connection] = connection
        end
      end

      def connection_db_config
        self.class.connection_db_config
      end
    end
  end
end
