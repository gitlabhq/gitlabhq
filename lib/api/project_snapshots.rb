module API
  class ProjectSnapshots < Grape::API
    helpers ::API::Helpers::ProjectSnapshotsHelpers

    before { authorize_read_git_snapshot! }

    resource :projects do
      desc 'Download a (possibly inconsistent) snapshot of a repository' do
        detail 'This feature was introduced in GitLab 10.7'
      end
      params do
        optional :wiki, type: Boolean, desc: 'Set to true to receive the wiki repository'
      end
      get ':id/snapshot' do
        send_git_snapshot(snapshot_repository)
      end
    end
  end
end
