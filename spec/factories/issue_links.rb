# frozen_string_literal: true

FactoryBot.define do
  factory :issue_link do
    source factory: :issue
    target factory: :issue
  end
end
