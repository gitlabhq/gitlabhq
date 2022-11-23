# frozen_string_literal: true

require_relative "../../../../spec_helper"
require_relative "../../../../helpers/contract_source_helper"
require_relative "../../../../helpers/publish_contract_helper"
require_relative "../../../../states/project/merge_request/show_state"

module Provider
  module DiffsBatchHelper
    Pact.service_provider "Merge Request Diffs Batch Endpoint" do
      app { Environments::Test.app }

      honours_pact_with "MergeRequest#show" do
        pact_uri Provider::ContractSourceHelper.contract_location(:GET_DIFFS_BATCH, :spec)
      end

      Provider::PublishContractHelper.publish_contract_setup.call(
        method(:app_version),
        method(:app_version_branch),
        method(:publish_verification_results)
      )
    end
  end
end
