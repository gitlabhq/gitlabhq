# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountImportedProjectsMetric < DatabaseMetric
          operation :count

          def initialize(metric_definition)
            super

            raise ArgumentError, "import_type options attribute is required" unless import_type.present?
          end

          relation { ::Project }

          start do |time_constraints|
            unless time_constraints.nil?
              start = time_constraints[:created_at]&.first

              unless start.nil?
                ::Project
                  .select(:id)
                  .where(Project.arel_table[:created_at].gteq(start))
                  .order(created_at: :asc).order(id: :asc).limit(1).first&.id
              end
            end
          end

          finish do |time_constraints|
            unless time_constraints.nil?
              finish = time_constraints[:created_at]&.last

              unless finish.nil?
                ::Project
                  .select(:id)
                  .where(Project.arel_table[:created_at].lteq(finish))
                  .order(created_at: :desc).order(id: :desc).limit(1).first&.id
              end
            end
          end

          private

          def relation
            super.imported_from(import_type)
          end

          def import_type
            options[:import_type]
          end
        end
      end
    end
  end
end
