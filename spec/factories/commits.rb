# frozen_string_literal: true

require_relative '../support/helpers/repo_helpers'

FactoryBot.define do
  factory :commit do
    transient do
      author { nil }
    end

    git_commit do
      commit = RepoHelpers.sample_commit

      if author
        commit.author_email = author.email
        commit.author_name = author.name
      end

      commit
    end

    project

    skip_create # Commits cannot be persisted

    initialize_with do
      new(git_commit, project)
    end

    after(:build) do |commit, evaluator|
      author = evaluator.author || build_stubbed(:author)
      stub_method(commit, :author) { author }
      stub_method(commit, :parent_ids) { [] }
    end

    trait :merge_commit do
      after(:build) do |commit|
        stub_method(commit, :parent_ids) { Array.new(2) { SecureRandom.hex(20) } }
      end
    end

    trait :without_author do
      after(:build) do |commit|
        stub_method(commit, :author) { nil }
      end
    end
  end
end
