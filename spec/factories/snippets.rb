# frozen_string_literal: true

FactoryBot.define do
  factory :project_snippet, class: :ProjectSnippet do
    # Project specific attributes
    project
    author { project.creator }
    organization { nil }

    # Shared attributes
    title { generate(:title) }
    content { generate(:title) }
    description { generate(:title) }
    file_name { generate(:filename) }
    secret { false }

    transient do
      repository_storage { 'default' }
    end

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
      after :create do |snippet, evaluator|
        snippet.track_snippet_repository(evaluator.repository_storage)

        # There are various tests that rely on there being no repository cache.
        # Using raw avoids caching.
        repo = Gitlab::GlRepository::SNIPPET.repository_for(snippet).raw
        repo.create_from_bundle(TestEnv.factory_repo_bundle_path)
      end
    end

    trait :empty_repo do
      after(:create) do |snippet|
        raise "Failed to create repository!" unless snippet.create_repository
      end
    end
  end

  # Using an inheritance from project_snippet to share traits
  factory :personal_snippet, parent: :project_snippet, class: :PersonalSnippet do
    author { association(:author, :with_namespace) }
    organization { author&.namespace&.organization || association(:organization) }
    project { nil }

    trait :secret do
      visibility_level { Snippet::PUBLIC }
      secret { true }
    end
  end
end
