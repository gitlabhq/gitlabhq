# frozen_string_literal: true

module Gitlab
  module HTTP_V2
    class Configuration
      attr_accessor :allowed_internal_uris, :log_exception_proc, :silent_mode_log_info_proc, :log_with_level_proc

      def log_exception(...)
        log_exception_proc&.call(...)
      end

      def silent_mode_log_info(...)
        silent_mode_log_info_proc&.call(...)
      end

      def log_with_level(...)
        log_with_level_proc&.call(...)
      end
    end
  end
end
