# frozen_string_literal: true

require_relative '../../../../spec_helper'
require_relative '../../../../helpers/publish_contract_helper'
require_relative '../../../../states/project/pipeline/show_state'

module Provider
  module GetPipelinesHeaderDataHelper
    Pact.service_provider "GET pipeline header data" do
      app { Environments::Test.app }

      honours_pact_with 'Pipelines#show' do
        pact_uri '../contracts/project/pipeline/show/pipelines#show-get_project_pipeline_header_data.json'
        # pact_uri 'http://localhost:9292/pacts/provider/GET%20pipeline%20header%20data/consumer/Pipelines%23show/latest'
      end

      app_version Provider::PublishContractHelper::PROVIDER_VERSION
      app_version_branch Provider::PublishContractHelper::PROVIDER_BRANCH
      publish_verification_results Provider::PublishContractHelper::PUBLISH_FLAG
    end
  end
end
