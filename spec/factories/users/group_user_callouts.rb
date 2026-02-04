# frozen_string_literal: true

FactoryBot.define do
  factory :group_callout, class: 'Users::GroupCallout' do
    feature_name { :preview_user_over_limit_free_plan_alert }

    user
    group
  end
end
