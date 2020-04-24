# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class BaseTask
        include Gitlab::WithRequestStore

        def initialize(opts, logger: Logger.new($stdout))
          @project_path = opts.fetch(:project_path)
          @file_path    = opts.fetch(:file_path)
          @namespace    = Namespace.find_by_full_path(opts.fetch(:namespace_path))
          @current_user = User.find_by_username(opts.fetch(:username))
          @measurement_enabled = opts.fetch(:measurement_enabled)
          @logger = logger
        end

        private

        attr_reader :project, :namespace, :current_user, :file_path, :project_path, :logger, :measurement_enabled

        def measurement_options
          {
            measurement_enabled: measurement_enabled,
            measurement_logger: logger
          }
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
