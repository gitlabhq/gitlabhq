# frozen_string_literal: true

module Repositories
  class LfsStorageController < ::Repositories::GitHttpClientController
    include LfsRequest
    include WorkhorseRequest
    include SendFileUpload

    skip_before_action :verify_workhorse_api!, only: :download

    # added here as a part of the refactor, will be removed
    # https://gitlab.com/gitlab-org/gitlab/-/issues/328692
    delegate :deploy_token, :user, to: :authentication_result, allow_nil: true
    urgency :medium, [:download, :upload_authorize]
    urgency :low, [:upload_finalize]

    def download
      lfs_object = LfsObject.find_by_oid(oid)
      return render_lfs_not_found unless lfs_object&.file&.exists?

      send_upload(lfs_object.file, send_params: { content_type: "application/octet-stream" })
    end

    def upload_authorize
      set_workhorse_internal_api_content_type

      # We don't actually know whether Workhorse received an LFS upload
      # request with a Content-Length header or `Transfer-Encoding:
      # chunked`.  Since we don't know, we need to be pessimistic and
      # set `has_length` to `false` so that multipart uploads will be
      # used for AWS. Otherwise, AWS will respond with `501 NOT IMPLEMENTED`
      # error because a PutObject request with `Transfer-Encoding: chunked`
      # is not supported.
      #
      # This is only an issue with object storage-specific settings, not
      # with consolidated object storage settings.
      authorized = LfsObjectUploader.workhorse_authorize(has_length: false, maximum_size: size)
      authorized.merge!(LfsOid: oid, LfsSize: size)

      render json: authorized
    end

    def upload_finalize
      service = Lfs::FinalizeUploadService.new(
        oid: oid,
        size: size,
        uploaded_file: uploaded_file,
        project: project,
        repository_type: repo_type.name
      )

      response = service.execute

      return head :ok, content_type: LfsRequest::CONTENT_TYPE if response.success?

      case response.reason
      when :invalid_record, :invalid_path, :remote_store_error
        render_lfs_forbidden
      when :invalid_uploaded_file
        render plain: 'SHA256 or size mismatch', status: :bad_request
      else
        render plain: 'Unprocessable entity', status: :unprocessable_entity
      end
    end

    private

    def download_request?
      action_name == 'download'
    end

    def upload_request?
      %w[upload_authorize upload_finalize].include? action_name
    end

    def oid
      params[:oid].to_s
    end

    def size
      params[:size].to_i
    end

    def uploaded_file
      params[:file]
    end
  end
end
