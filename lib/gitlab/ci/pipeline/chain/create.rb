# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Create < Chain::Base
          include Chain::Helpers

          def perform!
            BulkInsertableAssociations.with_bulk_insert do
              pipeline.save!
            end
          rescue ActiveRecord::RecordInvalid => e
            error("Failed to persist the pipeline: #{e}")
          end

          def break?
            !pipeline.persisted?
          end
        end
      end
    end
  end
end
