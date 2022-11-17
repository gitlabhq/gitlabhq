# frozen_string_literal: true

require_relative '../../../../spec_helper'
require_relative '../../../../helpers/publish_contract_helper'
require_relative '../../../../states/project/pipeline/show_state'

module Provider
  module DeletePipelineHelper
    Pact.service_provider "DELETE pipeline" do
      app { Environments::Test.app }

      honours_pact_with 'Pipelines#show' do
        pact_uri '../contracts/project/pipeline/show/pipelines#show-delete_pipeline.json'
      end

      app_version Provider::PublishContractHelper::PROVIDER_VERSION
      app_version_branch Provider::PublishContractHelper::PROVIDER_BRANCH
      publish_verification_results Provider::PublishContractHelper::PUBLISH_FLAG
    end
  end
end
