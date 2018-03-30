module Gitlab
  module ImportExport
    module AfterExportStrategies
      class BaseAfterExportStrategy
        include ActiveModel::Validations
        extend Forwardable

        StrategyError = Class.new(StandardError)

        AFTER_EXPORT_LOCK_FILE_NAME = '.after_export_action'.freeze

        private

        attr_reader :project, :current_user

        public

        def initialize(attributes = {})
          @options = OpenStruct.new(attributes)

          self.class.instance_eval do
            def_delegators :@options, *attributes.keys
          end
        end

        def execute(current_user, project)
          return unless project&.export_project_path

          @project = project
          @current_user = current_user

          if invalid?
            log_validation_errors

            return
          end

          create_or_update_after_export_lock
          strategy_execute

          true
        rescue => e
          project.import_export_shared.error(e)
          false
        ensure
          delete_after_export_lock
        end

        def to_json(options = {})
          @options.to_h.merge!(klass: self.class.name).to_json
        end

        def self.lock_file_path(project)
          return unless project&.export_path

          File.join(project.export_path, AFTER_EXPORT_LOCK_FILE_NAME)
        end

        protected

        def strategy_execute
          raise NotImplementedError
        end

        private

        def create_or_update_after_export_lock
          FileUtils.touch(self.class.lock_file_path(project))
        end

        def delete_after_export_lock
          lock_file = self.class.lock_file_path(project)

          FileUtils.rm(lock_file) if lock_file.present? && File.exist?(lock_file)
        end

        def log_validation_errors
          errors.full_messages.each { |msg| project.import_export_shared.add_error_message(msg) }
        end
      end
    end
  end
end
