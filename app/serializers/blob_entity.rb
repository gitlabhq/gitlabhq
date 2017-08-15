class BlobEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :path, :name, :mode

  expose :last_commit do |blob|
    request.project.repository.last_commit_for_path(blob.commit_id, blob.path)
  end

  expose :icon do |blob|
    IconsHelper.file_type_icon_class('file', blob.mode, blob.name)
  end

  expose :url do |blob|
    project_blob_path(request.project, File.join(request.ref, blob.path))
  end
end
