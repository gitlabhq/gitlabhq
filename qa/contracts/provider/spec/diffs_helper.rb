# frozen_string_literal: true

require_relative '../environments/local'

module DiffsHelper
  local = Environments::Local.new

  Pact.service_provider "Merge Request Diffs Endpoint" do
    app { local.merge_request('/diffs_batch.json?page=0') }

    honours_pact_with 'Merge Request Page' do
      pact_uri '../contracts/merge_request_page-merge_request_diffs_endpoint.json'
    end
  end
end
