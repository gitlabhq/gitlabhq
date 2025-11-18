# frozen_string_literal: true

module Gitlab
  module BackgroundOperation
    # Background operation used for testing purpose only
    class DummyTest < BaseOperationWorker
      operation_name :touch_all
      feature_category :database
      cursor :id

      def perform
        each_sub_batch do |relation|
          relation.touch_all
        end
      end
    end
  end
end
