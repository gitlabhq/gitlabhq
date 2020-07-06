# frozen_string_literal: true

require "json"

module Resolvers
  module CiConfiguration
    class SastResolver < BaseResolver
      SAST_UI_SCHEMA_PATH = 'app/validators/json_schemas/security_ci_configuration_schemas/sast_ui_schema.json'

      type ::Types::CiConfiguration::Sast::Type, null: true

      def resolve(**args)
        Gitlab::Json.parse(File.read(Rails.root.join(SAST_UI_SCHEMA_PATH)))
      end
    end
  end
end
