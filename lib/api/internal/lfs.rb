# frozen_string_literal: true

module API
  module Internal
    class Lfs < ::API::Base
      use Rack::Sendfile, 'X-Sendfile'

      # gitlab-shell authenticates via a shared secret, so the global
      # organization hook has no user; derive from gl_repository instead.
      skip_global_organization_setup!

      before { authenticate_by_gitlab_shell_token! }
      before { set_current_organization_from_repository }

      feature_category :source_code_management

      helpers ::API::Helpers::InternalHelpers

      helpers do
        def find_lfs_object(lfs_oid)
          LfsObject.find_by_oid(lfs_oid)
        end
      end

      namespace 'internal' do
        namespace 'lfs' do
          desc 'Get LFS URL for object ID' do
            detail 'This feature was introduced in GitLab 13.5.'
          end
          params do
            requires :oid, type: String, desc: 'The object ID to query'
            requires :gl_repository, type: String, desc: "Project identifier (e.g. project-1)"
          end
          route_setting :authorization, skip_granular_token_authorization: :gitlab_shell_token_auth
          get "/", urgency: :high do
            lfs_object = find_lfs_object(params[:oid])

            not_found! unless lfs_object

            not_found! unless repo_type.project? && project
            not_found! unless lfs_object.project_allowed_access?(project)

            file = lfs_object.file

            not_found! unless file&.exists?

            content_type 'application/octet-stream'

            if file.file_storage?
              sendfile file.path
            else
              send_workhorse_headers!(*Gitlab::Workhorse.send_url(file.url))
              env['api.format'] = :binary
              body ""
            end
          end
        end
      end
    end
  end
end
