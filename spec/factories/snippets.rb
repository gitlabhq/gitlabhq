FactoryGirl.define do
  sequence :title, aliases: [:content] do
    FFaker::Lorem.sentence
  end

  sequence :file_name do
    FFaker::Internet.user_name
  end

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
