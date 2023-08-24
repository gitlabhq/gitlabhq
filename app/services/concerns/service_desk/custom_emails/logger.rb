# frozen_string_literal: true

module ServiceDesk
  module CustomEmails
    module Logger
      private

      def log_warning(error_message: nil)
        with_context do
          Gitlab::AppLogger.warn(build_log_message(error_message: error_message))
        end
      end

      def log_info(error_message: nil)
        with_context do
          Gitlab::AppLogger.info(build_log_message(error_message: error_message))
        end
      end

      def with_context(&block)
        Gitlab::ApplicationContext.with_context(
          related_class: self.class.to_s,
          user: current_user,
          project: project,
          &block
        )
      end

      def log_category
        'custom_email'
      end

      def build_log_message(error_message: nil)
        {
          category: log_category,
          error_message: error_message
        }.compact
      end
    end
  end
end
