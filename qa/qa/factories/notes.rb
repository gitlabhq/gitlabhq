# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/notes.html
    factory :issue_note, class: 'QA::Resource::ProjectIssueNote'
  end
end
