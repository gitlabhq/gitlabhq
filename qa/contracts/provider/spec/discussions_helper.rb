# frozen_string_literal: true

require_relative '../environments/local'

module DiscussionsHelper
  local = Environments::Local.new

  Pact.service_provider "Merge Request Discussions Endpoint" do
    app { local.merge_request('/discussions.json') }

    honours_pact_with 'Merge Request Page' do
      pact_uri '../contracts/merge_request_page-merge_request_discussions_endpoint.json'
    end
  end
end
