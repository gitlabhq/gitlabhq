# frozen_string_literal: true

FactoryBot.define do
  factory :project_deploy_token do
    project
    deploy_token
  end
end
