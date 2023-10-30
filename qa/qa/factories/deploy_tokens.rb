# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/deploy_tokens.html#create-a-project-deploy-token
    factory :project_deploy_token, class: 'QA::Resource::ProjectDeployToken'

    # https://docs.gitlab.com/ee/api/deploy_tokens.html#create-a-group-deploy-token
    factory :group_deploy_token, class: 'QA::Resource::GroupDeployToken'
  end
end
