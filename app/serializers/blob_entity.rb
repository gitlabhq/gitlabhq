# frozen_string_literal: true

class BlobEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :path, :name, :mode

  expose :readable_text?, as: :readable_text

  expose :icon do |blob|
    IconsHelper.file_type_icon_class('file', blob.mode, blob.name)
  end

  expose :url, if: ->(*) { request.respond_to?(:ref) } do |blob|
    project_blob_path(request.project, File.join(request.ref, blob.path))
  end
end

BlobEntity.prepend_mod_with('BlobEntity')
