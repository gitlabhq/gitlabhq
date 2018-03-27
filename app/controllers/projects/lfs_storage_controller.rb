class Projects::LfsStorageController < Projects::GitHttpClientController
  include LfsRequest
  include WorkhorseRequest
  include SendFileUpload

  skip_before_action :verify_workhorse_api!, only: [:download, :upload_finalize]

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
    render json: Gitlab::Workhorse.lfs_upload_ok(oid, size)
  end

  def upload_finalize
    unless tmp_filename
      render_lfs_forbidden
      return
    end

    if store_file(oid, size, tmp_filename)
      head 200
    else
      render plain: 'Unprocessable entity', status: 422
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

  def tmp_filename
    name = request.headers['X-Gitlab-Lfs-Tmp']
    return if name.include?('/')
    return unless oid.present? && name.start_with?(oid)

    name
  end

  def store_file(oid, size, tmp_file)
    # Define tmp_file_path early because we use it in "ensure"
    tmp_file_path = File.join(LfsObjectUploader.workhorse_upload_path, tmp_file)

    object = LfsObject.find_or_create_by(oid: oid, size: size)
    file_exists = object.file.exists? || move_tmp_file_to_storage(object, tmp_file_path)
    file_exists && link_to_project(object)
  ensure
    FileUtils.rm_f(tmp_file_path)
  end

  def move_tmp_file_to_storage(object, path)
    object.file = File.open(path)
    object.file.store!
    object.save
  end

  def link_to_project(object)
    if object && !object.projects.exists?(storage_project.id)
      object.projects << storage_project
      object.save
    end
  end
end
