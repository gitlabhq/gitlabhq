# frozen_string_literal: true

require_relative "../../../../spec_helper"
require_relative "../../../../helpers/contract_source_helper"
require_relative "../../../../helpers/publish_contract_helper"
require_relative "../../../../states/project/merge_requests/show_state"

module Provider
  module DiffsBatchHelper
    Pact.service_provider "GET diffs batch" do
      app { Environments::Test.app }

      honours_pact_with "MergeRequests#show" do
        pact_uri Provider::ContractSourceHelper.contract_location(requester: :spec, file_path: __FILE__)
      end

      Provider::PublishContractHelper.publish_contract_setup.call(
        method(:app_version),
        method(:app_version_branch),
        method(:publish_verification_results)
      )
    end
  end
end
