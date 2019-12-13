# frozen_string_literal: true

class PrometheusMetric < ApplicationRecord
  belongs_to :project, validate: true, inverse_of: :prometheus_metrics

  enum group: {
    # built-in groups
    nginx_ingress_vts: -1,
    ha_proxy: -2,
    aws_elb: -3,
    nginx: -4,
    kubernetes: -5,
    nginx_ingress: -6,

    # custom/user groups
    business: 0,
    response: 1,
    system: 2
  }

  GROUP_DETAILS = {
    # built-in groups
    nginx_ingress_vts: {
      group_title: _('Response metrics (NGINX Ingress VTS)'),
      required_metrics: %w(nginx_upstream_responses_total nginx_upstream_response_msecs_avg),
      priority: 10
    }.freeze,
    nginx_ingress: {
      group_title: _('Response metrics (NGINX Ingress)'),
      required_metrics: %w(nginx_ingress_controller_requests nginx_ingress_controller_ingress_upstream_latency_seconds_sum),
      priority: 10
    }.freeze,
    ha_proxy: {
      group_title: _('Response metrics (HA Proxy)'),
      required_metrics: %w(haproxy_frontend_http_requests_total haproxy_frontend_http_responses_total),
      priority: 10
    }.freeze,
    aws_elb: {
      group_title: _('Response metrics (AWS ELB)'),
      required_metrics: %w(aws_elb_request_count_sum aws_elb_latency_average aws_elb_httpcode_backend_5_xx_sum),
      priority: 10
    }.freeze,
    nginx: {
      group_title: _('Response metrics (NGINX)'),
      required_metrics: %w(nginx_server_requests nginx_server_requestMsec),
      priority: 10
    }.freeze,
    kubernetes: {
      group_title: _('System metrics (Kubernetes)'),
      required_metrics: %w(container_memory_usage_bytes container_cpu_usage_seconds_total),
      priority: 5
    }.freeze,

    # custom/user groups
    business: {
      group_title: _('Business metrics (Custom)'),
      priority: 0
    }.freeze,
    response: {
      group_title: _('Response metrics (Custom)'),
      priority: -5
    }.freeze,
    system: {
      group_title: _('System metrics (Custom)'),
      priority: -10
    }.freeze
  }.freeze

  validates :title, presence: true
  validates :query, presence: true
  validates :group, presence: true
  validates :y_label, presence: true
  validates :unit, presence: true

  validates :project, presence: true, unless: :common?
  validates :project, absence: true, if: :common?

  scope :common, -> { where(common: true) }

  def priority
    group_details(group).fetch(:priority)
  end

  def group_title
    group_details(group).fetch(:group_title)
  end

  def required_metrics
    group_details(group).fetch(:required_metrics, []).map(&:to_s)
  end

  def to_query_metric
    Gitlab::Prometheus::Metric.new(id: id, title: title, required_metrics: required_metrics, weight: 0, y_label: y_label, queries: queries)
  end

  def queries
    [
      {
        query_range: query,
        unit: unit,
        label: legend,
        series: query_series
      }.compact
    ]
  end

  def query_series
    case legend
    when 'Status Code'
      [{
        label: 'status_code',
        when: [
          { value: '2xx', color: 'green' },
          { value: '4xx', color: 'orange' },
          { value: '5xx', color: 'red' }
        ]
      }]
    end
  end

  private

  def group_details(group)
    GROUP_DETAILS.fetch(group.to_sym)
  end
end
