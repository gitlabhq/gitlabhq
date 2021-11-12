# frozen_string_literal: true

module API
  module Internal
    class Lfs < ::API::Base
      use Rack::Sendfile

      before { authenticate_by_gitlab_shell_token! }

      feature_category :source_code_management

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
          get "/", urgency: :high do
            lfs_object = find_lfs_object(params[:oid])

            not_found! unless lfs_object

            _, project, repo_type = Gitlab::GlRepository.parse(params[:gl_repository])

            not_found! unless repo_type.project? && project
            not_found! unless lfs_object.project_allowed_access?(project)

            file = lfs_object.file

            not_found! unless file&.exists?

            content_type 'application/octet-stream'

            if file.file_storage?
              sendfile file.path
            else
              workhorse_headers = Gitlab::Workhorse.send_url(file.url)
              header workhorse_headers[0], workhorse_headers[1]
              env['api.format'] = :binary
              body ""
            end
          end
        end
      end
    end
  end
end
