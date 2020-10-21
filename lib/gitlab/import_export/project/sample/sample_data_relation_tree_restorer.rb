# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      module Sample
        class SampleDataRelationTreeRestorer < RelationTreeRestorer
          DATE_MODELS = %i[issues milestones].freeze

          def initialize(*args)
            super

            date_calculator
          end

          private

          def build_relation(relation_key, relation_definition, data_hash)
            # Override due date attributes in data hash for Sample Data templates
            # Dates are moved by taking the closest one to average and moving that (and rest around it) to the date of import
            # TODO: To move this logic to RelationFactory (see: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41699#note_430465333)
            override_date_attributes!(relation_key, data_hash)
            super
          end

          def override_date_attributes!(relation_key, data_hash)
            return unless DATE_MODELS.include?(relation_key.to_sym)

            data_hash['start_date'] = date_calculator.calculate_by_closest_date_to_average(data_hash['start_date'].to_time) unless data_hash['start_date'].nil?
            data_hash['due_date'] = date_calculator.calculate_by_closest_date_to_average(data_hash['due_date'].to_time) unless data_hash['due_date'].nil?
          end

          # TODO: Move clear logic into main comsume_relation method (see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41699#note_430465330)
          def dates
            unless relation_reader.legacy?
              DATE_MODELS.map do |tag|
                relation_reader.consume_relation(@importable_path, tag).map { |model| model.first['due_date'] }.tap do
                  relation_reader.clear_consumed_relations
                end
              end
            end
          end

          def date_calculator
            @date_calculator ||= Gitlab::ImportExport::Project::Sample::DateCalculator.new(dates)
          end
        end
      end
    end
  end
end
