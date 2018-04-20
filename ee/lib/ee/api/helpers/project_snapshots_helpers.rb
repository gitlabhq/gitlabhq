module EE
  module API
    module Helpers
      module ProjectSnapshotsHelpers
        extend ::Gitlab::Utils::Override

        # Allow Geo nodes to access snapshots by presenting a valid JWT
        override :authorize_read_git_snapshot!
        def authorize_read_git_snapshot!
          if gitlab_geo_node_token?
            require_node_to_be_enabled!
            authenticate_by_gitlab_geo_node_token!
          else
            super
          end
        end

        # Skip checking authorization of current_user if authenticated via Geo
        override :snapshot_project
        def snapshot_project
          if gitlab_geo_node_token?
            project = find_project(params[:id])
            not_found!('Project') if project.nil?

            project
          else
            super
          end
        end
      end
    end
  end
end
