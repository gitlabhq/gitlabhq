# frozen_string_literal: true

FactoryBot.define do
  factory :project_callout, class: 'Users::ProjectCallout' do
    feature_name { :awaiting_members_banner }

    user
    project
  end
end
