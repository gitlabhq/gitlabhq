module Projects
  module ImportExport
    class Shared
      def initialize(opts)
        @opts = opts
      end

      def export_path
        @export_path ||= Projects::ImportExport.export_path(relative_path: @opts[:relative_path])
      end
    end
  end
end