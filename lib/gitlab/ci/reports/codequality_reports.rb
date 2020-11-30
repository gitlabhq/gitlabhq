# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class CodequalityReports
        attr_reader :degradations, :error_message

        CODECLIMATE_SCHEMA_PATH = Rails.root.join('app', 'validators', 'json_schemas', 'codeclimate.json').to_s

        def initialize
          @degradations = {}.with_indifferent_access
          @error_message = nil
        end

        def add_degradation(degradation)
          valid_degradation?(degradation) && @degradations[degradation.dig('fingerprint')] = degradation
        end

        def set_error_message(error)
          @error_message = error
        end

        def degradations_count
          @degradations.size
        end

        def all_degradations
          @degradations.values
        end

        private

        def valid_degradation?(degradation)
          JSON::Validator.validate!(CODECLIMATE_SCHEMA_PATH, degradation)
        rescue JSON::Schema::ValidationError => e
          set_error_message("Invalid degradation format: #{e.message}")
          false
        end
      end
    end
  end
end
