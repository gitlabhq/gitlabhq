# frozen_string_literal: true

module VirtualRegistries
  class CachedResponseUploader < GitlabUploader
    include ObjectStorage::Concern

    storage_location :dependency_proxy

    alias_method :upload, :model

    before :cache, :set_content_type

    def store_dir
      dynamic_segment
    end

    private

    def set_content_type(file)
      file.content_type = model.content_type
    end

    def dynamic_segment
      model.object_storage_key
    end
  end
end
