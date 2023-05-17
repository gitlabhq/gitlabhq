# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      module Sample
        class RelationTreeRestorer < ImportExport::Project::RelationTreeRestorer
          def initialize(...)
            super(...)

            @date_calculator = Gitlab::ImportExport::Project::Sample::DateCalculator.new(dates)
          end

          private

          def relation_factory_params(*args)
            super.merge(date_calculator: @date_calculator)
          end

          def dates
            RelationFactory::DATE_MODELS.flat_map do |tag|
              @relation_reader.consume_relation(@importable_path, tag, mark_as_consumed: false).map do |model|
                model.first['due_date']
              end
            end
          end
        end
      end
    end
  end
end
