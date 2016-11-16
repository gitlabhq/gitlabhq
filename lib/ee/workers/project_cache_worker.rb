module EE
  module Workers
    # Geo specific code for cache re-generation
    #
    # This module is intended to encapsulate EE-specific methods
    # and be **prepended** in the `ProjectCacheWorker` class.
    module ProjectCacheWorker
      def update_caches(project_id)
        if ::Gitlab::Geo.secondary?
          update_geo_caches(project_id)
        else
          super
        end
      end

      private

      # Geo should only update Redis based cache, as data store in the database
      # will be updated on primary and replicated to the secondaries.
      def update_geo_caches(project_id)
        project = Project.find(project_id)

        return unless project.repository.exists?

        if project.repository.root_ref
          project.repository.build_cache
        end
      end
    end
  end
end
