module Gitlab
  module Prometheus
    class Query
      include ActiveModel::Model
###       unit: req / sec
      # series:
      #   - label: code
      # when:
      #   - value: 2xx
      # color: green
      # - value: 4xx
      # color: yellow
      # - value: 5xx
      # color: red

      attr_accessor :unit, :sereis
      attr_accessor :title, :required_metrics, :weight, :y_label, :queries

      validates :title, :required_metrics, :weight, :y_label, :queries, presence: true

      def initialize(params = {})
        super(params)
        @y_label ||= 'Values'
      end
    end
  end
end
