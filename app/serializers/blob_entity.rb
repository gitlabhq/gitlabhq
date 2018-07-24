# frozen_string_literal: true

class BlobEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :path, :name, :mode

  expose :readable_text?, as: :readable_text

  expose :icon do |blob|
    IconsHelper.file_type_icon_class('file', blob.mode, blob.name)
  end

  expose :url, if: -> (*) { request.respond_to?(:ref) } do |blob|
    project_blob_path(request.project, File.join(request.ref, blob.path))
  end

  expose :file_lock, if: -> (*) { request.respond_to?(:ref) }, using: FileLockEntity do |blob|
    if request.project.root_ref?(request.ref)
      request.project.find_path_lock(blob.path, exact_match: true)
    end
  end
end
