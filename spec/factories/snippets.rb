FactoryGirl.define do
  factory :snippet do
    author
    title { generate(:title) }
    content { generate(:title) }
    file_name { generate(:filename) }

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
