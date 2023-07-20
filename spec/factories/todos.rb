# frozen_string_literal: true

FactoryBot.define do
  factory :todo do
    project
    author { project&.creator || user }
    user { project&.creator || user }
    target factory: :issue
    action { Todo::ASSIGNED }

    trait :assigned do
      action { Todo::ASSIGNED }
    end

    trait :review_requested do
      action { Todo::REVIEW_REQUESTED }
    end

    trait :mentioned do
      action { Todo::MENTIONED }
    end

    trait :directly_addressed do
      action { Todo::DIRECTLY_ADDRESSED }
    end

    trait :build_failed do
      action { Todo::BUILD_FAILED }
      target factory: :merge_request
    end

    trait :marked do
      action { Todo::MARKED }
    end

    trait :approval_required do
      action { Todo::APPROVAL_REQUIRED }
    end

    trait :unmergeable do
      action { Todo::UNMERGEABLE }
    end

    trait :member_access_requested do
      action { Todo::MEMBER_ACCESS_REQUESTED }
    end

    trait :review_submitted do
      action { Todo::REVIEW_SUBMITTED }
    end

    trait :pending do
      state { :pending }
    end

    trait :done do
      state { :done }
    end
  end

  factory :on_commit_todo, class: 'Todo' do
    project
    author
    user
    action { Todo::ASSIGNED }
    commit_id { RepoHelpers.sample_commit.id }
    target_type { "Commit" }
  end
end
