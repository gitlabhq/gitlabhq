# frozen_string_literal: true

require_relative '../../../../spec_helper'
require_relative '../../../../states/project/pipeline/index_state'

module Provider
  module GetListProjectPipelinesHelper
    Pact.service_provider "GET List project pipelines" do
      app { Environments::Test.app }

      honours_pact_with 'Pipelines#index' do
        pact_uri '../contracts/project/project/pipeline/index/pipelines#index-get_list_project_pipelines.json'
      end

      app_version Provider::PublishContractHelper::PROVIDER_VERSION
      app_version_branch Provider::PublishContractHelper::PROVIDER_BRANCH
      publish_verification_results Provider::PublishContractHelper::PUBLISH_FLAG
    end
  end
end
