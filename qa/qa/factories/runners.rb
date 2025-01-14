# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :deprecated_group_runner, class: 'QA::Resource::Ci::DeprecatedGroupRunner'
    factory :group_runner, class: 'QA::Resource::Ci::GroupRunner'
    factory :project_runner, class: 'QA::Resource::Ci::ProjectRunner'
    factory :runner_manager, class: 'QA::Resource::Ci::RunnerManager'
  end
end
