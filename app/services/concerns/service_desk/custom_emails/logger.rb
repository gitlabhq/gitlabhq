# frozen_string_literal: true

module ServiceDesk
  module CustomEmails
    module Logger
      private

      def log_warning(**args)
        with_context do
          Gitlab::AppLogger.warn(build_log_message(**args))
        end
      end

      def log_info(error_message: nil, project: nil)
        with_context(project: project) do
          Gitlab::AppLogger.info(build_log_message(error_message: error_message))
        end
      end

      def with_context(project: nil, &block)
        Gitlab::ApplicationContext.with_context(
          related_class: self.class.to_s,
          user: current_user,
          project: project || self.project,
          &block
        )
      end

      def log_category
        'custom_email'
      end

      def build_log_message(**args)
        {
          category: log_category
        }.merge(args).compact
      end
    end
  end
end
