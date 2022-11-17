# frozen_string_literal: true

require_relative '../../../../spec_helper'
require_relative '../../../../states/project/merge_request/show_state'

module Provider
  module DiffsBatchHelper
    Pact.service_provider "Merge Request Diffs Batch Endpoint" do
      app { Environments::Test.app }

      honours_pact_with 'MergeRequest#show' do
        pact_uri '../contracts/project/merge_request/show/mergerequest#show-merge_request_diffs_batch_endpoint.json'
      end

      Provider::PublishContractHelper.publish_contract_setup.call
    end
  end
end
