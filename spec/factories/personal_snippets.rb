FactoryGirl.define do
  factory :personal_snippet, parent: :snippet, class: :PersonalSnippet do
    trait :public do
      visibility_level PersonalSnippet::PUBLIC
    end

    trait :internal do
      visibility_level PersonalSnippet::INTERNAL
    end

    trait :private do
      visibility_level PersonalSnippet::PRIVATE
    end
  end
end
