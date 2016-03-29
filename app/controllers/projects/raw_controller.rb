# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath
  include BlobHelper

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show
    @blob = @repository.blob_at(@commit.id, @path)

    if @blob
      headers['X-Content-Type-Options'] = 'nosniff'

      return if cached_blob?

      if @blob.lfs_pointer?
        send_lfs_object
      else
        headers.store(*Gitlab::Workhorse.send_git_blob(@repository, @blob))
        headers['Content-Disposition'] = 'inline'
        headers['Content-Type'] = safe_content_type(@blob)
        head :ok # 'render nothing: true' messes up the Content-Type
      end
    else
      render_404
    end
  end

  private

  def send_lfs_object
    lfs_object = find_lfs_object

    if lfs_object && lfs_object.project_allowed_access?(@project)
      send_file lfs_object.file.path, filename: @blob.name, disposition: 'attachment'
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
