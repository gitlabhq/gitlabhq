require_relative '../support/repo_helpers'

FactoryGirl.define do
  factory :commit do
    git_commit RepoHelpers.sample_commit
    project factory: :empty_project

    initialize_with do
      new(git_commit, project)
    end
  end
end
