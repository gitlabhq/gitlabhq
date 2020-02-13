# frozen_string_literal: true

FactoryBot.define do
  factory :project_authorization do
    user
    project
    access_level { Gitlab::Access::REPORTER }
  end
end
