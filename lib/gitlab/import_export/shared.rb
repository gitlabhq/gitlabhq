module Gitlab
  module ImportExport
    class Shared
      attr_reader :errors, :opts

      def initialize(opts)
        @opts = opts
        @errors = []
      end

      def export_path
        @export_path ||= Gitlab::ImportExport.export_path(relative_path: opts[:relative_path])
      end

      def error(error)
        error_out(error.message, caller[0].dup)
        @errors << error.message
        # Debug:
        Rails.logger.error(error.backtrace)
      end

      private

      def error_out(message, caller)
        Rails.logger.error("Import/Export error raised on #{caller}: #{message}")
      end
    end
  end
end
