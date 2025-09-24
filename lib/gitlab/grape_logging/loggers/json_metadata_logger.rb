# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class JsonMetadataLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, _)
          metadata = request.env[::Gitlab::Middleware::JsonValidation::RACK_ENV_METADATA_KEY]

          return {} unless metadata

          # Add a json_ prefix to distinguish from the limits
          metadata.transform_keys { |key| "json_#{key}" }
        end
      end
    end
  end
end
