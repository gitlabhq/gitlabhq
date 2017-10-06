FactoryGirl.define do
  factory :upload do
    model { build(:project) }
    path { "uploads/-/system/project/avatar/avatar.jpg" }
    size 100.kilobytes
    uploader "AvatarUploader"

    trait :personal_snippet do
      model { build(:personal_snippet) }
      uploader "PersonalFileUploader"
    end
  end
end
