# frozen_string_literal: true

FactoryBot.define do
  factory :group_deploy_keys_group do
    group_deploy_key
    group
    can_push { true }
  end
end
