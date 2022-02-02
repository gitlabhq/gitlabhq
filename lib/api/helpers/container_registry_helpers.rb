# frozen_string_literal: true

module API
  module Helpers
    module ContainerRegistryHelpers
      extend ActiveSupport::Concern

      included do
        rescue_from Faraday::Error, ::ContainerRegistry::Path::InvalidRegistryPathError do |e|
          service_unavailable!('We are having trouble connecting to the Container Registry. If this error persists, please review the troubleshooting documentation.')
        end
      end
    end
  end
end
