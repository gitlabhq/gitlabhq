# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/branches.html
    factory :branch, class: 'QA::Resource::Repository::Branch'

    # https://docs.gitlab.com/ee/api/protected_branches.html
    factory :protected_branch, class: 'QA::Resource::ProtectedBranch'
  end
end
