# frozen_string_literal: true

module Gitlab
  module Database
    module Transaction
      class Settings
        ALLOWED_CONFIGS = %w[
          LOCK_TIMEOUT
        ].freeze

        InvalidConfigError = Class.new(StandardError)

        class << self
          def with(config_name, value, connection = ApplicationRecord.connection)
            old_value = get(config_name, connection)

            set(config_name, value, connection)

            yield

            set(config_name, old_value, connection)
          end

          def set(config_name, value, connection = ApplicationRecord.connection)
            check_allowed!(config_name)

            quoted_value = connection.quote(value)
            query = "SET LOCAL #{config_name} = #{quoted_value}"

            connection.exec_query(query)
          end

          def get(config_name, connection = ApplicationRecord.connection)
            check_allowed!(config_name)

            connection.select_all("SHOW #{config_name}").rows[0][0]
          end

          def check_allowed!(config_name)
            return if ALLOWED_CONFIGS.include?(config_name)

            raise InvalidConfigError, "Config #{config_name} is not allowed"
          end
        end
      end
    end
  end
end
