# frozen_string_literal: true

module API
  class ProjectSnapshots < ::API::Base
    helpers ::API::Helpers::ProjectSnapshotsHelpers

    before { authorize_read_git_snapshot! }

    feature_category :source_code_management

    resource :projects do
      desc 'Download snapshot of a Git repository' do
        detail 'Downloads snapshot of a Git repository.'
        success File
        tags ['project_snapshots']
        produces 'application/x-tar'
        failure [
          { code: 401, message: 'Unauthorized' }
        ]
      end
      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        optional :wiki, type: Boolean, desc: 'Set to true to receive the wiki repository'
      end
      route_setting :authorization, permissions: :read_snapshot, boundary_type: :project
      get ':id/snapshot' do
        send_git_snapshot(snapshot_repository)
      end
    end
  end
end
