module Ci
  class Build
    module Eraseable
      include ActiveSupport::Concern

      def erase!
        raise StandardError, 'Build not eraseable!' unless eraseable?
        remove_artifacts_file!
        remove_artifacts_metadata!
        erase_trace!
      end

      def eraseable?
        complete? && (artifacts_file.exists? || !trace_empty?)
      end

      def erase_url
        if eraseable?
          erase_namespace_project_build_path(project.namespace, project, self)
        end
      end

      private

      def erase_trace!
        File.truncate(path_to_trace, 0) if File.file?(path_to_trace)
      end
    end
  end
end
