# frozen_string_literal: true

module QA
  # https://docs.gitlab.com/ee/api/commits.html
  FactoryBot.define do
    factory :commit, class: 'QA::Resource::Repository::Commit'
  end
end
