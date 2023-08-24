# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :project_runner, class: 'QA::Resource::ProjectRunner'
    factory :group_runner, class: 'QA::Resource::GroupRunner'
  end
end
