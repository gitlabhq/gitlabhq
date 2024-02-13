# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :group_access_token, class: 'QA::Resource::GroupAccessToken'
    factory :personal_access_token, class: 'QA::Resource::PersonalAccessToken'
    factory :project_access_token, class: 'QA::Resource::ProjectAccessToken'
  end
end
