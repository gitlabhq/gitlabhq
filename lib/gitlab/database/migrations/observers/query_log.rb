# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module Observers
        class QueryLog < MigrationObserver
          def before
            @logger_was = ActiveRecord::Base.logger
            file_path = File.join(output_dir, "migration.log")
            @logger = Logger.new(file_path)
            ActiveRecord::Base.logger = @logger
          end

          def after
            ActiveRecord::Base.logger = @logger_was
            @logger.close
          end

          def record
            # no-op
          end
        end
      end
    end
  end
end
