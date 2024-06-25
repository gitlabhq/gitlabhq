# frozen_string_literal: true

FactoryBot.define do
  factory :upload do
    model { association(:project) }
    size { 100.kilobytes }
    uploader { "AvatarUploader" }
    mount_point { :avatar }
    secret { nil }
    store { ObjectStorage::Store::LOCAL }
    version { RecordsUploads::Concern::VERSION }

    # we should build a mount agnostic upload by default
    transient do
      filename { 'avatar.jpg' }
    end

    path do
      uploader_instance = Object.const_get(uploader.to_s, false).new(model, mount_point)
      File.join(uploader_instance.store_dir, filename)
    end

    trait :personal_snippet_upload do
      model { association(:personal_snippet) }
      path { File.join(secret, filename) }
      uploader { "PersonalFileUploader" }
      secret { SecureRandom.hex }
      mount_point { nil }
    end

    trait :issuable_upload do
      uploader { "FileUploader" }
      path { File.join(secret, filename) }
      secret { SecureRandom.hex }
      mount_point { nil }
    end

    trait :with_file do
      after(:create) do |upload|
        FileUtils.mkdir_p(File.dirname(upload.absolute_path))
        FileUtils.touch(upload.absolute_path)
      end
    end

    trait :object_storage do
      store { ObjectStorage::Store::REMOTE }
    end

    trait :namespace_upload do
      model { association(:group) }
      path { File.join(secret, filename) }
      uploader { "NamespaceFileUploader" }
      secret { SecureRandom.hex }
      mount_point { nil }
    end

    trait :favicon_upload do
      model { association(:appearance) }
      uploader { "FaviconUploader" }
      secret { SecureRandom.hex }
      mount_point { :favicon }
    end

    trait :attachment_upload do
      mount_point { :attachment }
      model { association(:note) }
      uploader { "AttachmentUploader" }
    end

    trait :design_action_image_v432x230_upload do
      mount_point { :image_v432x230 }
      model { association(:design_action) }
      uploader { DesignManagement::DesignV432x230Uploader.name }
    end
  end
end
