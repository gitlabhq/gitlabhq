class PrometheusMetric < ActiveRecord::Base
  belongs_to :project, required: true, validate: true
  enum group: [:business, :response, :system]

  validates :title, presence: true
  validates :query, presence: true
  validates :group, presence: true

  GROUP_TITLES = {
    business: 'Business metrics',
    response: 'Response metrics',
    system: 'System metrics'
  }.freeze

  def group_title
    GROUP_TITLES[group.to_sym]
  end

  def to_query_metric
    Gitlab::Prometheus::Metric.new(title: title, required_metrics: [], weight: 0, y_label: y_label, queries: build_queries)
  end

  private

  def build_queries
    [
      {
        query_range: query,
        unit: unit,
        label: legend
      }
    ]
  end
end
