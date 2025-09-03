# frozen_string_literal: true

# This service list all existent Lfs objects in a repository
module Projects
  module LfsPointers
    class LfsListService < BaseService
      # Retrieve all lfs blob pointers and returns a hash
      # with the structure { lfs_file_oid => lfs_file_size }
      def execute
        return {} unless project&.lfs_enabled?

        lfs_changes = if Feature.enabled?(:mirroring_lfs_optimization,
          project) && params[:updated_revisions] != ['--all']
                        Gitlab::Git::LfsChanges.new(project.repository,
                          params[:updated_revisions]).new_pointers(not_in: [])
                      else
                        Gitlab::Git::LfsChanges.new(project.repository).all_pointers
                      end

        lfs_changes.map! { |blob| [blob.lfs_oid, blob.lfs_size] }.to_h
      end
    end
  end
end
