# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ResetAutoDuoCodeReviewFalseValues < BatchedMigrationJob
      operation_name :update_all
      feature_category :code_review_workflow

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(auto_duo_code_review_enabled: false)
                   .update_all(auto_duo_code_review_enabled: nil)
        end
      end
    end
  end
end
