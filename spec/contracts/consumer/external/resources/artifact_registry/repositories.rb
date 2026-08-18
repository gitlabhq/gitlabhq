# frozen_string_literal: true

require 'faraday'

module ArtifactRegistry
  module Resources
    # HTTP client calls for the Artifact Registry repositories endpoint.
    #
    # TODO: Replace with a direct call to ArtifactRegistry::Client once it is
    # implemented in the Rails monolith. This Faraday implementation is a PoC
    # placeholder modelled from the S17 management API spec.
    module Repositories
      # Lists repositories for a given namespace slug.
      #
      # @param slug     [String] the namespace slug
      # @param base_url [String] the mock service base URL (injected by Pact)
      # @return [Faraday::Response]
      def self.list(slug:, base_url:)
        Faraday.new(url: base_url) do |conn|
          conn.headers['Accept'] = 'application/json'
        end.get("/api/v1/#{slug}/repositories", limit: 20)
      end
    end
  end
end
