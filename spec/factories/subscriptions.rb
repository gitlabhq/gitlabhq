# frozen_string_literal: true

FactoryBot.define do
  factory :subscription do
    project
    user { project.creator }
    subscribable factory: :issue
  end
end
