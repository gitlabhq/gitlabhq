FactoryBot.define do
  factory :upload do
    model { build(:project) }
    path { "uploads/-/system/project/avatar/avatar.jpg" }
    size 100.kilobytes
    uploader "AvatarUploader"

    trait :personal_snippet do
      model { build(:personal_snippet) }
      uploader "PersonalFileUploader"
    end

    trait :issuable_upload do
      path { "#{SecureRandom.hex}/myfile.jpg" }
      uploader "FileUploader"
    end

    trait :namespace_upload do
      path { "#{SecureRandom.hex}/myfile.jpg" }
      model { build(:group) }
      uploader "NamespaceFileUploader"
    end
  end
end
