FactoryGirl.define do
  sequence(:title, aliases: [:content]) { |n| "My snippet #{n}" }
  sequence(:file_name) { |n| "snippet-#{n}.rb" }

  factory :snippet do
    author
    title
    content
    file_name

    trait :public do
      visibility_level Snippet::PUBLIC
    end

    trait :internal do
      visibility_level Snippet::INTERNAL
    end

    trait :private do
      visibility_level Snippet::PRIVATE
    end
  end
end
