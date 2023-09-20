# frozen_string_literal: true

module Enums
  module PrometheusMetric
    def self.groups
      {
        # built-in groups
        nginx_ingress_vts: -1,
        ha_proxy: -2,
        aws_elb: -3,
        nginx: -4,
        kubernetes: -5,
        nginx_ingress: -6,
        cluster_health: -100
      }.merge(custom_groups).freeze
    end

    # custom/user groups
    def self.custom_groups
      {
        business: 0,
        response: 1,
        system: 2,
        custom: 3
      }.freeze
    end

    def self.group_details
      {
        # built-in groups
        nginx_ingress_vts: {
          group_title: _('Response metrics (NGINX Ingress VTS)'),
          required_metrics: %w[nginx_upstream_responses_total nginx_upstream_response_msecs_avg],
          priority: 10
        }.freeze,
        nginx_ingress: {
          group_title: _('Response metrics (NGINX Ingress)'),
          required_metrics: %w[nginx_ingress_controller_requests nginx_ingress_controller_ingress_upstream_latency_seconds_sum],
          priority: 10
        }.freeze,
        ha_proxy: {
          group_title: _('Response metrics (HA Proxy)'),
          required_metrics: %w[haproxy_frontend_http_requests_total haproxy_frontend_http_responses_total],
          priority: 10
        }.freeze,
        aws_elb: {
          group_title: _('Response metrics (AWS ELB)'),
          required_metrics: %w[aws_elb_request_count_sum aws_elb_latency_average aws_elb_httpcode_backend_5_xx_sum],
          priority: 10
        }.freeze,
        nginx: {
          group_title: _('Response metrics (NGINX)'),
          required_metrics: %w[nginx_server_requests nginx_server_requestMsec],
          priority: 10
        }.freeze,
        kubernetes: {
          group_title: _('System metrics (Kubernetes)'),
          required_metrics: %w[container_memory_usage_bytes container_cpu_usage_seconds_total],
          priority: 5
        }.freeze,
        cluster_health: {
          group_title: _('Cluster Health'),
          required_metrics: %w[container_memory_usage_bytes container_cpu_usage_seconds_total],
          priority: 10
        }.freeze
      }.merge(custom_group_details).freeze
    end

    # custom/user groups
    def self.custom_group_details
      {
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
        }.freeze,
        custom: {
          group_title: _('Custom metrics'),
          priority: 0
        }
      }.freeze
    end
  end
end
