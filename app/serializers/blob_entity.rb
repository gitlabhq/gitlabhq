class BlobEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :path, :name, :mode

  expose :icon do |blob|
    IconsHelper.file_type_icon_class('file', blob.mode, blob.name)
  end

  expose :url do |blob|
    namespace_project_blob_path(request.project.namespace, request.project, File.join(request.ref, blob.path))
  end
end
