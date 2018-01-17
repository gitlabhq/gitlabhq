FactoryBot.define do
  factory :protected_tag_create_access_level, class: ProtectedTag::CreateAccessLevel do
    user nil
    group nil
    protected_tag
    access_level { Gitlab::Access::DEVELOPER }
  end
end
