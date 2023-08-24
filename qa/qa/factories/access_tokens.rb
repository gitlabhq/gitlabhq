# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :project_access_token, class: 'QA::Resource::ProjectAccessToken'
    factory :group_access_token, class: 'QA::Resource::GroupAccessToken'
  end
end
