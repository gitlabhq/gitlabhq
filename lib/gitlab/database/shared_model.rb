# frozen_string_literal: true

module Gitlab
  module Database
    # This abstract class is used for models which need to exist in multiple de-composed databases.
    class SharedModel < ActiveRecord::Base
      self.abstract_class = true

      # if shared model is used, this allows to limit connections
      # on which this model is being shared
      class_attribute :limit_connection_names, default: nil

      class << self
        def using_connection(connection)
          previous_connection = self.overriding_connection

          unless previous_connection.nil? || previous_connection.equal?(connection)
            raise 'cannot nest connection overrides for shared models with different connections'
          end

          self.overriding_connection = connection

          yield
        ensure
          self.overriding_connection = nil unless previous_connection.equal?(self.overriding_connection)
        end

        def connection
          if connection = self.overriding_connection
            connection
          else
            super
          end
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
