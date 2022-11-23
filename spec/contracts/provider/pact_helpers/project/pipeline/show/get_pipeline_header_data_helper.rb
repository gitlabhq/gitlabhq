# frozen_string_literal: true

require_relative "../../../../spec_helper"
require_relative "../../../../helpers/contract_source_helper"
require_relative "../../../../helpers/publish_contract_helper"
require_relative "../../../../states/project/pipeline/show_state"

module Provider
  module GetPipelinesHeaderDataHelper
    include PublishContractHelper

    Pact.service_provider "GET pipeline header data" do
      app { Environments::Test.app }

      honours_pact_with "Pipelines#show" do
        pact_uri Provider::ContractSourceHelper.contract_location(:GET_PIPELINE_HEADER_DATA, :spec)
      end

      publish_contract_setup.call
    end
  end
end
