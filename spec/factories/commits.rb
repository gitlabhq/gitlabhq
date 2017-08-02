require_relative '../support/repo_helpers'

FactoryGirl.define do
  factory :commit do
    git_commit RepoHelpers.sample_commit
    project factory: :empty_project

    initialize_with do
      new(git_commit, project)
    end

    after(:build) do |commit|
      allow(commit).to receive(:author).and_return build(:author)
    end

    trait :without_author do
      after(:build) do |commit|
        allow(commit).to receive(:author).and_return nil
      end
    end
  end
end
