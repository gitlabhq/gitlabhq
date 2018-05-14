# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath
  include BlobHelper
  include SendFileUpload

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show
    @blob = @repository.blob_at(@commit.id, @path)

    if @blob
      headers['X-Content-Type-Options'] = 'nosniff'

      return if cached_blob?

      if @blob.stored_externally?
        send_lfs_object
      else
        send_git_blob @repository, @blob
      end
    else
      render_404
    end
  end

  private

  def send_lfs_object
    lfs_object = find_lfs_object

    if lfs_object && lfs_object.project_allowed_access?(@project)
      send_upload(lfs_object.file, attachment: @blob.name)
    else
      render_404
    end
  end

  def find_lfs_object
    lfs_object = LfsObject.find_by_oid(@blob.lfs_oid)
    if lfs_object && lfs_object.file.exists?
      lfs_object
    else
      nil
    end
  end
end
