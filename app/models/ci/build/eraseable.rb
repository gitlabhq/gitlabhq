module Ci
  class Build
    module Eraseable
      extend ActiveSupport::Concern

      included do
        belongs_to :erased_by, class_name: 'User'
      end

      def erase!(opts = {})
        raise StandardError, 'Build not eraseable!' unless eraseable?

        remove_artifacts_file!
        remove_artifacts_metadata!
        erase_trace!
        update_erased!(opts[:erased_by])
      end

      def eraseable?
        complete? && (artifacts? || has_trace?)
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

      def update_erased!(user = nil)
        self.erased_by = user if user
        self.erased_at = Time.now
        self.erased = true
        self.save!
      end
    end
  end
end
