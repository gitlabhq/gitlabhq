class PrometheusMetric < ActiveRecord::Base
  belongs_to :project, required: true, validate: true, inverse_of: :prometheus_metrics
  enum group: [:business, :response, :system]

  validates :title, presence: true
  validates :query, presence: true
  validates :group, presence: true
  validates :y_label, presence: true
  validates :unit, presence: true
  validates :legend, presence: true

  GROUP_TITLES = {
    business: _('Business metrics'),
    response: _('Response metrics'),
    system: _('System metrics')
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
