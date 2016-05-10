module Gitlab
  module ImportExport
    class Shared

      attr_reader :errors

      def initialize(opts)
        @opts = opts
        @errors = []
      end

      def export_path
        @export_path ||= Gitlab::ImportExport.export_path(relative_path: @opts[:relative_path])
      end

      def error(message)
        error_out(message, caller[0].dup)
        @errors << message
      end

      private

      def error_out(message, caller)
        Rails.logger.error("Import/Export error raised on #{caller}: #{message}")
      end
    end
  end
end
