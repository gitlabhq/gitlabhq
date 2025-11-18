# frozen_string_literal: true

module Gitlab
  module Tracking
    module Destinations
      class SnowplowContextValidator
        def validate!(context)
          Array.wrap(context).each do |item|
            json = item.with_indifferent_access
            validate_against_schema(json[:schema], json[:data])
          end
        end

        private

        def validate_against_schema(schema_url, data)
          return unless schema_url.start_with?('iglu:com.gitlab') # No need to verify payloads from standard plugins

          schema_definition = fetch_schema_from_iglu(schema_url)
          return unless schema_definition

          validator = JSONSchemer.schema(schema_definition)
          errors = validator.validate(data).to_a

          return unless errors.any?

          error_messages = errors.map { |error| JSONSchemer::Errors.pretty(error) }

          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
            ArgumentError.new("Snowplow context data does not match schema: #{error_messages.join(' ')}"),
            schema_url: schema_url,
            data: data,
            validation_errors: error_messages
          )
        end

        def fetch_schema_from_iglu(schema_url)
          cache_key = "snowplow:schema:#{schema_url}"

          Rails.cache.fetch(cache_key, expires_in: 1.hour, skip_nil: true) do
            fetch_schema_from_iglu_without_cache(schema_url)
          end
        end

        def fetch_schema_from_iglu_without_cache(schema_url)
          url = "https://gitlab-org.gitlab.io/iglu/schemas/#{schema_url.delete_prefix('iglu:')}"

          response = Gitlab::HTTP.get(url, allow_local_requests: true, timeout: 5)

          if response.success?
            Gitlab::Json.parse(response.body).except('$schema') # we dont need to resolve schema with JSONSchemer
          else
            Gitlab::AppJsonLogger.warn(message: "Failed to fetch Snowplow schema from Iglu registry",
              status_code: response.code,
              schema_url: schema_url)
            nil
          end
        end
      end
    end
  end
end
