# frozen_string_literal: true

module API
  class ProjectSnapshots < ::API::Base
    helpers ::API::Helpers::ProjectSnapshotsHelpers

    before { authorize_read_git_snapshot! }

    feature_category :source_code_management

    resource :projects do
      desc 'Download a (possibly inconsistent) snapshot of a repository' do
        detail 'This feature was introduced in GitLab 10.7'
        success File
        tags ['project_snapshots']
        produces 'application/x-tar'
        failure [
          { code: 401, message: 'Unauthorized' }
        ]
      end
      params do
        optional :wiki, type: Boolean, desc: 'Set to true to receive the wiki repository'
      end
      route_setting :authorization, permissions: :read_snapshot, boundary_type: :project
      get ':id/snapshot' do
        send_git_snapshot(snapshot_repository)
      end
    end
  end
end
