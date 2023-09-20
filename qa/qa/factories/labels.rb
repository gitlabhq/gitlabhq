# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :project_label, class: 'QA::Resource::ProjectLabel'
    factory :group_label, class: 'QA::Resource::GroupLabel'
  end
end
