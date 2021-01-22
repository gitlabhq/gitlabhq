# frozen_string_literal: true

module Repositories
  class LfsStorageController < Repositories::GitHttpClientController
    include LfsRequest
    include WorkhorseRequest
    include SendFileUpload

    skip_before_action :verify_workhorse_api!, only: :download

    def download
      lfs_object = LfsObject.find_by_oid(oid)
      unless lfs_object && lfs_object.file.exists?
        render_lfs_not_found
        return
      end

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
      if store_file!(oid, size)
        head 200, content_type: LfsRequest::CONTENT_TYPE
      else
        render plain: 'Unprocessable entity', status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordInvalid
      render_lfs_forbidden
    rescue UploadedFile::InvalidPathError
      render_lfs_forbidden
    rescue ObjectStorage::RemoteStoreError
      render_lfs_forbidden
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

    # rubocop: disable CodeReuse/ActiveRecord
    def store_file!(oid, size)
      object = LfsObject.find_by(oid: oid, size: size)

      if object
        replace_file!(object) unless object.file&.exists?
      else
        object = create_file!(oid, size)
      end

      return unless object

      link_to_project!(object)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_file!(oid, size)
      return unless uploaded_file.is_a?(UploadedFile)

      LfsObject.create!(oid: oid, size: size, file: uploaded_file)
    end

    def replace_file!(lfs_object)
      raise UploadedFile::InvalidPathError unless uploaded_file.is_a?(UploadedFile)

      Gitlab::AppJsonLogger.info(message: "LFS file replaced because it did not exist", oid: oid, size: size)
      lfs_object.file = uploaded_file
      lfs_object.save!
    end

    def link_to_project!(object)
      return unless object

      LfsObjectsProject.safe_find_or_create_by!(
        project: project,
        lfs_object: object
      )
    end
  end
end
