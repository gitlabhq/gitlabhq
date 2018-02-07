FactoryBot.define do
  factory :upload do
    model { build(:project) }
    size 100.kilobytes
    uploader "AvatarUploader"
    mount_point :avatar
    secret nil

    # we should build a mount agnostic upload by default
    transient do
      filename 'myfile.jpg'
    end

    # this needs to comply with RecordsUpload::Concern#upload_path
    path { File.join("uploads/-/system", model.class.to_s.underscore, mount_point.to_s, 'avatar.jpg') }

    trait :personal_snippet_upload do
      uploader "PersonalFileUploader"
      path { File.join(secret, filename) }
      model { build(:personal_snippet) }
      secret SecureRandom.hex
    end

    trait :issuable_upload do
      uploader "FileUploader"
      path { File.join(secret, filename) }
      secret SecureRandom.hex
    end

    trait :namespace_upload do
      model { build(:group) }
      path { File.join(secret, filename) }
      uploader "NamespaceFileUploader"
      secret SecureRandom.hex
    end

    trait :attachment_upload do
      transient do
        mount_point :attachment
      end

      model { build(:note) }
      uploader "AttachmentUploader"
    end
  end
end
