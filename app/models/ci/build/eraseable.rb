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

      def erased?
        !self.erased_at.nil?
      end

      private

      def erase_trace!
        self.trace = nil
      end

      def update_erased!(user = nil)
        self.update(erased_by: user, erased_at: Time.now)
      end
    end
  end
end
