module EE
  module Workers
    # Geo specific code for cache re-generation
    #
    # This module is intended to encapsulate EE-specific methods
    # and be **prepended** in the `ProjectCacheWorker` class.
    module ProjectCacheWorker
      def perform(*args)
        if ::Gitlab::Geo.secondary?
          perform_geo_secondary(*args)
        else
          super
        end
      end

      private

      # Geo should only update Redis based cache, as data store in the database
      # will be updated on primary and replicated to the secondaries.
      # rubocop: disable CodeReuse/ActiveRecord
      def perform_geo_secondary(project_id, refresh = [])
        project = ::Project.find_by(id: project_id)

        return unless project && project.repository.exists?

        project.repository.refresh_method_caches(refresh.map(&:to_sym))
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
