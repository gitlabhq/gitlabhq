# frozen_string_literal: true
require_relative "contract_sources"

module Provider
  module ContractSourceHelper
    def self.contract_location(provider, requester)
      provider_name = Provider::ContractSources::CONTRACT_SOURCES[provider]

      if ENV["PACT_BROKER"]
        provider_name[:broker]
      else
        paths = Provider::ContractSources::RELATIVE_PATHS
        prefix_path = requester == :rake ? File.expand_path(paths[requester], __dir__) : paths[requester]
        "#{prefix_path}#{provider_name[:local]}"
      end
    end
  end
end
