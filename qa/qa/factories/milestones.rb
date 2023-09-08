# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :project_milestone, class: 'QA::Resource::ProjectMilestone'
    factory :group_milestone, class: 'QA::Resource::GroupMilestone'
  end
end
