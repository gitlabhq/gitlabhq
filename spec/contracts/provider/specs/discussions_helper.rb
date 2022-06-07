# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../states/discussions_state'

module Provider
  module DiscussionsHelper
    Pact.service_provider "Merge Request Discussions Endpoint" do
      app { Environments::Test.app }

      honours_pact_with 'Merge Request Page' do
        pact_uri '../contracts/merge_request_page-merge_request_discussions_endpoint.json'
      end
    end
  end
end
