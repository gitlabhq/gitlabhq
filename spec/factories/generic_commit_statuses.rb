# frozen_string_literal: true

FactoryBot.define do
  factory :generic_commit_status, class: 'GenericCommitStatus', parent: :commit_status do
    name { 'generic' }
    description { 'external commit status' }
  end
end
