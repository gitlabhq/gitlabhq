module Gitlab
  module Prometheus
    class Query
      include ActiveModel::Model
      include ActiveRecord::Base
      enum

      attr_accessor :unit, :series_dsl, :label, :type

      validates :title, :required_metrics, :weight, :y_label, :queries, presence: true

      def initialize(params = {})
        super(params)
        @y_label ||= 'Values'
      end
    end
  end
end
