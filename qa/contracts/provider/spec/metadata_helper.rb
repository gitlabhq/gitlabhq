# frozen_string_literal: true

require_relative '../spec_helper'

module Provider
  module MetadataHelper
    local = Environments::Local.new

    Pact.service_provider "Merge Request Metadata Endpoint" do
      app { local.merge_request('/diffs_metadata.json') }

      honours_pact_with 'Merge Request Page' do
        pact_uri '../contracts/merge_request_page-merge_request_metadata_endpoint.json'
      end
    end
  end
end
