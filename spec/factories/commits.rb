require_relative '../support/repo_helpers'

FactoryGirl.define do
  factory :commit do
    git_commit RepoHelpers.sample_commit
    project factory: :empty_project
    author { build(:author) }

    initialize_with do
      new(git_commit, project)
    end

    trait :without_author do
      author nil
    end
  end
end
