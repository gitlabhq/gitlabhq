# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class CodequalityReports
        attr_reader :degradations, :error_message

        SEVERITY_PRIORITIES = %w(blocker critical major minor info).map.with_index.to_h.freeze # { "blocker" => 0, "critical" => 1 ... }
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

        def sort_degradations!
          @degradations = @degradations.sort_by do |_fingerprint, degradation|
            SEVERITY_PRIORITIES[degradation.dig(:severity)]
          end.to_h
        end

        private

        def valid_degradation?(degradation)
          JSONSchemer.schema(Pathname.new(CODECLIMATE_SCHEMA_PATH)).valid?(degradation)
        rescue StandardError => _
          false
        end
      end
    end
  end
end
