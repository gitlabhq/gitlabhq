# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class BaseTask
        def initialize(opts, logger: Logger.new($stdout))
          @project_path = opts.fetch(:project_path)
          @file_path    = opts.fetch(:file_path)
          @namespace    = Namespace.find_by_full_path(opts.fetch(:namespace_path))
          @current_user = User.find_by_username(opts.fetch(:username))
          @logger = logger
        end

        private

        attr_reader :project, :namespace, :current_user, :file_path, :project_path, :logger

        def disable_upload_object_storage
          overwrite_uploads_setting('enabled', false) do
            yield
          end
        end

        def overwrite_uploads_setting(key, value)
          old_value = Settings.uploads.object_store[key]
          Settings.uploads.object_store[key] = value

          yield

        ensure
          Settings.uploads.object_store[key] = old_value
        end

        def success(message)
          logger.info(message)

          true
        end

        def error(message)
          logger.error(message)

          false
        end
      end
    end
  end
end
