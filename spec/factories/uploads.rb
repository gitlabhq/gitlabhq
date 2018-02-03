FactoryBot.define do
  factory :upload do
    model { build(:project) }
    size 100.kilobytes
    uploader "AvatarUploader"
    store ObjectStorage::Store::LOCAL

    # we should build a mount agnostic upload by default
    transient do
      mounted_as :avatar
      secret SecureRandom.hex
    end

    # this needs to comply with RecordsUpload::Concern#upload_path
    path { File.join("uploads/-/system", model.class.to_s.underscore, mounted_as.to_s, 'avatar.jpg') }

    trait :personal_snippet_upload do
      model { build(:personal_snippet) }
      path { File.join(secret, 'myfile.jpg') }
      uploader "PersonalFileUploader"
    end

    trait :issuable_upload do
      path { File.join(secret, 'myfile.jpg') }
      uploader "FileUploader"
    end

    trait :object_storage do
      store ObjectStorage::Store::REMOTE
    end

    trait :namespace_upload do
      model { build(:group) }
      path { File.join(secret, 'myfile.jpg') }
      uploader "NamespaceFileUploader"
    end

    trait :attachment_upload do
      transient do
        mounted_as :attachment
      end

      model { build(:note) }
      uploader "AttachmentUploader"
    end
  end
end
