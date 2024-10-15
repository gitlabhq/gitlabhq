# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class CodequalityReports
        attr_reader :degradations, :error_message

        SEVERITY_PRIORITIES = %w[blocker critical major minor info unknown].map.with_index.to_h.freeze # { "blocker" => 0, "critical" => 1 ... }
        CODECLIMATE_SCHEMA_PATH = Rails.root.join('app', 'validators', 'json_schemas', 'codeclimate.json').to_s

        def initialize
          @degradations = {}.with_indifferent_access
          @error_message = nil
        end

        def add_degradation(degradation)
          valid_degradation?(degradation) && @degradations[degradation['fingerprint']] = degradation
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
            severity = degradation[:severity]&.downcase
            SEVERITY_PRIORITIES[severity] || SEVERITY_PRIORITIES['unknown']
          end.to_h
        end

        def valid_degradation?(degradation)
          JSONSchemer.schema(Pathname.new(CODECLIMATE_SCHEMA_PATH)).valid?(degradation)
        rescue StandardError => _
          false
        end

        def code_quality_report_summary
          report_degradations = @degradations.presence
          return if report_degradations.nil?

          summary = ::Gitlab::Ci::Reports::CodequalityReports::SEVERITY_PRIORITIES.keys.index_with(0)
          report_degradations.each_value do |degradation|
            summary[degradation[:severity]] += 1
          end
          summary['count'] = summary.values.sum
          summary
        end
      end
    end
  end
end
