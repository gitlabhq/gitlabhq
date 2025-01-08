# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Errors
        class DatabaseBackupError < StandardError
          attr_reader :config, :db_file_name

          def initialize(config, db_file_name)
            @config = config
            @db_file_name = db_file_name

            super(build_message)
          end

          private

          def build_message
            "Failed to create compressed file '#{db_file_name}' " \
              "when trying to backup the main database:\n - host: " \
              "'#{config[:host]}'\n - port: '#{config[:port]}'\n - " \
              "database: '#{config[:database]}'"
          end
        end
      end
    end
  end
end
