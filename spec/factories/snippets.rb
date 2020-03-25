# frozen_string_literal: true

FactoryBot.define do
  factory :snippet do
    author
    title { generate(:title) }
    content { generate(:title) }
    description { generate(:title) }
    file_name { generate(:filename) }
    secret { false }

    trait :public do
      visibility_level { Snippet::PUBLIC }
    end

    trait :internal do
      visibility_level { Snippet::INTERNAL }
    end

    trait :private do
      visibility_level { Snippet::PRIVATE }
    end

    # Test repository - https://gitlab.com/gitlab-org/gitlab-test
    trait :repository do
      after :create do |snippet|
        TestEnv.copy_repo(snippet,
          bare_repo: TestEnv.factory_repo_path_bare,
          refs: TestEnv::BRANCH_SHA)

        snippet.track_snippet_repository(snippet.repository.storage)
      end
    end

    trait :empty_repo do
      after(:create) do |snippet|
        raise "Failed to create repository!" unless snippet.create_repository
      end
    end
  end

  factory :project_snippet, parent: :snippet, class: :ProjectSnippet do
    project
    author { project.creator }
  end

  factory :personal_snippet, parent: :snippet, class: :PersonalSnippet do
    trait :secret do
      visibility_level { Snippet::PUBLIC }
      secret { true }
      project { nil }
    end
  end
end
