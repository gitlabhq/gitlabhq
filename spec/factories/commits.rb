require_relative '../support/repo_helpers'

FactoryBot.define do
  factory :commit do
    transient do
      author nil
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

    initialize_with do
      new(git_commit, project)
    end

    after(:build) do |commit, evaluator|
      allow(commit).to receive(:author).and_return(evaluator.author || build_stubbed(:author))
    end

    trait :without_author do
      after(:build) do |commit|
        allow(commit).to receive(:author).and_return nil
      end
    end
  end
end
