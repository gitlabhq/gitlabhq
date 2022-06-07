# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../states/diffs_state'

module Provider
  module DiffsHelper
    Pact.service_provider "Merge Request Diffs Endpoint" do
      app { Environments::Test.app }

      honours_pact_with 'Merge Request Page' do
        pact_uri '../contracts/merge_request_page-merge_request_diffs_endpoint.json'
      end
    end
  end
end
