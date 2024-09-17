# frozen_string_literal: true

FactoryBot.define do
  factory :group_deploy_token do
    group
    association :deploy_token, :group
  end
end
