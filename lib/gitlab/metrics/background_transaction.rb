# frozen_string_literal: true

module Gitlab
  module Metrics
    class BackgroundTransaction < Transaction
      def initialize(worker_class)
        super()
        @worker_class = worker_class
      end

      def labels
        { controller: @worker_class.name, action: 'perform', feature_category: @worker_class.try(:get_feature_category).to_s }
      end
    end
  end
end
