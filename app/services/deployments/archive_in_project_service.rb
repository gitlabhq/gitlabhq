# frozen_string_literal: true

module Deployments
  # This service archives old deploymets and deletes deployment refs for
  # keeping the project repository performant.
  class ArchiveInProjectService < ::BaseService
    BATCH_SIZE = 100

    def execute
      deployments = Deployment.archivables_in(project, limit: BATCH_SIZE)

      return success(result: :empty) if deployments.empty?

      ids = deployments.map(&:id)
      ref_paths = deployments.map(&:ref_path)

      project.repository.delete_refs(*ref_paths)
      project.deployments.id_in(ids).update_all(archived: true)

      success(result: :archived, count: ids.count)
    end
  end
end
