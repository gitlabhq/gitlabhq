# frozen_string_literal: true

FactoryBot.define do
  factory :snippet do
    author
    title { generate(:title) }
    content { generate(:title) }
    description { generate(:title) }
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

  factory :project_snippet, parent: :snippet, class: :ProjectSnippet do
    project
    author { project.creator }
  end

  factory :personal_snippet, parent: :snippet, class: :PersonalSnippet do
  end
end
