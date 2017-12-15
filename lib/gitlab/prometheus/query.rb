module Gitlab
  module Prometheus
    class Query
      include ActiveModel::Model
      # include ActiveRecord::Base

      attr_accessor :unit, :series_dsl, :label, :type, :track

      validates :title, :required_metrics, :weight, :y_label, :queries, presence: true

      def initialize(params = {})
        super(params)
      end
    end
  end
end
