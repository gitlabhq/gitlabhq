# frozen_string_literal: true

module Repositories
  class LfsApiController < ::Repositories::GitHttpClientController
    include LfsRequest
    include Gitlab::Utils::StrongMemoize

    LFS_TRANSFER_CONTENT_TYPE = 'application/octet-stream'
    # Downloading directly with presigned URLs via batch requests
    # require longer expire time.
    # The 1h should be enough to download 100 objects.
    LFS_DIRECT_BATCH_EXPIRE_IN = 3600.seconds

    skip_before_action :lfs_check_access!, only: [:deprecated]
    before_action :lfs_check_batch_operation!, only: [:batch]

    # added here as a part of the refactor, will be removed
    # https://gitlab.com/gitlab-org/gitlab/-/issues/328692
    delegate :deploy_token, :user, to: :authentication_result, allow_nil: true
    urgency :medium, [:batch]

    def batch
      unless objects.present?
        render_lfs_not_found
        return
      end

      if download_request?
        render json: { objects: download_objects! }, content_type: LfsRequest::CONTENT_TYPE
      elsif upload_request?
        render json: { objects: upload_objects! }, content_type: LfsRequest::CONTENT_TYPE
      else
        raise "Never reached"
      end
    end

    def deprecated
      render(
        json: {
          message: _('Server supports batch API only, please update your Git LFS client to version 1.0.1 and up.'),
          documentation_url: "#{Gitlab.config.gitlab.url}/help"
        },
        content_type: LfsRequest::CONTENT_TYPE,
        status: :not_implemented
      )
    end

    private

    def download_request?
      params[:operation] == 'download'
    end

    def upload_request?
      params[:operation] == 'upload'
    end

    def download_objects!
      existing_oids = project.lfs_objects
        .for_oids(objects_oids)
        .index_by(&:oid)

      guest_can_download = ::Users::Anonymous.can?(:download_code, project)

      objects.each do |object|
        if lfs_object = existing_oids[object[:oid]]
          object[:actions] = download_actions(object, lfs_object)

          object[:authenticated] = true if guest_can_download
        else
          object[:error] = {
            code: 404,
            message: _("Object does not exist on the server or you don't have permissions to access it")
          }
        end
      end

      objects
    end

    def upload_objects!
      existing_oids = project.lfs_objects_oids(oids: objects_oids)

      objects.each do |object|
        next if existing_oids.include?(object[:oid])
        next if should_auto_link? && oids_from_fork.include?(object[:oid]) && link_to_project!(object)

        object[:actions] = upload_actions(object)
      end

      objects
    end

    def download_actions(object, lfs_object)
      lfs_file = lfs_object.file
      if lfs_file.file_storage? || lfs_file.proxy_download_enabled?
        proxy_download_actions(object)
      else
        direct_download_actions(lfs_object)
      end
    end

    def direct_download_actions(lfs_object)
      {
        download: {
          href: lfs_object.file.url(
            content_type: "application/octet-stream",
            expire_at: LFS_DIRECT_BATCH_EXPIRE_IN.since
          )
        }
      }
    end

    def proxy_download_actions(object)
      {
        download: {
          href: "#{project.http_url_to_repo}/gitlab-lfs/objects/#{object[:oid]}",
          header: {
            Authorization: authorization_header
          }.compact
        }
      }
    end

    def upload_actions(object)
      {
        upload: {
          href: "#{upload_http_url_to_repo}/gitlab-lfs/objects/#{object[:oid]}/#{object[:size]}",
          header: upload_headers
        }
      }
    end

    # Overridden in EE
    def upload_http_url_to_repo
      Gitlab::RepositoryUrlBuilder.build(repository.full_path, protocol: :http)
    end

    def upload_headers
      {
        Authorization: authorization_header,
        # git-lfs v2.5.0 sets the Content-Type based on the uploaded file. This
        # ensures that Workhorse can intercept the request.
        'Content-Type': LFS_TRANSFER_CONTENT_TYPE,
        'Transfer-Encoding': 'chunked'
      }
    end

    def lfs_check_batch_operation!
      if batch_operation_disallowed?
        render(
          json: {
            message: lfs_read_only_message
          },
          content_type: LfsRequest::CONTENT_TYPE,
          status: :forbidden
        )
      end
    end

    # Overridden in EE
    def batch_operation_disallowed?
      upload_request? && Gitlab::Database.read_only?
    end

    # Overridden in EE
    def lfs_read_only_message
      _('You cannot write to this read-only GitLab instance.')
    end

    def authorization_header
      strong_memoize(:authorization_header) do
        lfs_auth_header || request.headers['Authorization']
      end
    end

    def lfs_auth_header
      return unless user

      Gitlab::LfsToken.new(user, project).basic_encoding
    end

    def should_auto_link?
      return false unless project.forked?

      # Sanity check in case for some reason the user doesn't have access to the parent
      can?(user, :download_code, project.fork_source)
    end

    def oids_from_fork
      @oids_from_fork ||= project.lfs_objects_oids_from_fork_source(oids: objects_oids)
    end

    def link_to_project!(object)
      lfs_object = LfsObject.for_oid_and_size(object[:oid], object[:size])

      return unless lfs_object

      LfsObjectsProject.link_to_project!(lfs_object, project, repo_type.name)

      Gitlab::AppJsonLogger.info(
        message: "LFS object auto-linked to forked project",
        lfs_object_oid: lfs_object.oid,
        lfs_object_size: lfs_object.size,
        source_project_id: project.fork_source.id,
        source_project_path: project.fork_source.full_path,
        target_project_id: project.project_id,
        target_project_path: project.full_path
      )
    end
  end
end

::Repositories::LfsApiController.prepend_mod_with('Repositories::LfsApiController')
