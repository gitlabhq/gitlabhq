# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../states/metadata_state'

module Provider
  module MetadataHelper
    Pact.service_provider "Merge Request Metadata Endpoint" do
      app { Environments::Test.app }

      honours_pact_with 'Merge Request Page' do
        pact_uri '../contracts/merge_request_page-merge_request_metadata_endpoint.json'
      end
    end
  end
end
