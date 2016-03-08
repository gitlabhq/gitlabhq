module Projects
  module ImportExport
    class Shared
      def initialize(opts)
        @opts = opts
      end

      def export_path
        @export_path ||= ImportExport.export_path(project_name: @opts[:project_name])
      end
    end
  end
end