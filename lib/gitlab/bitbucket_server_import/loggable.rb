# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Loggable
      def log_debug(messages)
        logger.debug(log_data(messages))
      end

      def log_info(messages)
        logger.info(log_data(messages))
      end

      def log_warn(messages)
        logger.warn(log_data(messages))
      end

      def log_error(messages)
        logger.error(log_data(messages))
      end

      private

      def logger
        Gitlab::BitbucketServerImport::Logger
      end

      def log_data(messages)
        messages.merge(log_base_data)
      end

      def log_base_data
        {
          class: self.class.name,
          project_id: project.id,
          project_path: project.full_path
        }
      end
    end
  end
end
