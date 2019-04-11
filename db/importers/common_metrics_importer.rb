# frozen_string_literal: true

module Importers
  class PrometheusMetric < ActiveRecord::Base
    enum group: {
      # built-in groups
      nginx_ingress_vts: -1,
      ha_proxy: -2,
      aws_elb: -3,
      nginx: -4,
      kubernetes: -5,
      nginx_ingress: -6,

      # custom groups
      business: 0,
      response: 1,
      system: 2
    }

    scope :common, -> { where(common: true) }

    GROUP_TITLES = {
      business: _('Business metrics (Custom)'),
      response: _('Response metrics (Custom)'),
      system: _('System metrics (Custom)'),
      nginx_ingress_vts: _('Response metrics (NGINX Ingress VTS)'),
      nginx_ingress: _('Response metrics (NGINX Ingress)'),
      ha_proxy: _('Response metrics (HA Proxy)'),
      aws_elb: _('Response metrics (AWS ELB)'),
      nginx: _('Response metrics (NGINX)'),
      kubernetes: _('System metrics (Kubernetes)')
    }.freeze
  end

  class CommonMetricsImporter
    MissingQueryId = Class.new(StandardError)

    attr_reader :content

    def initialize(filename = 'common_metrics.yml')
      @content = YAML.load_file(Rails.root.join('config', 'prometheus', filename))
    end

    def execute
      PrometheusMetric.reset_column_information

      process_content do |id, attributes|
        find_or_build_metric!(id)
          .update!(**attributes)
      end
    end

    private

    def process_content(&blk)
      content['panel_groups'].map do |group|
        process_group(group, &blk)
      end
    end

    def process_group(group, &blk)
      attributes = {
        group: find_group_title_key(group['group'])
      }

      group['panels'].map do |panel|
        process_panel(panel, attributes, &blk)
      end
    end

    def process_panel(panel, attributes, &blk)
      attributes = attributes.merge(
        title: panel['title'],
        y_label: panel['y_label'])

      panel['metrics'].map do |metric_details|
        process_metric_details(metric_details, attributes, &blk)
      end
    end

    def process_metric_details(metric_details, attributes, &blk)
      attributes = attributes.merge(
        legend: metric_details['label'],
        query: metric_details['query_range'],
        unit: metric_details['unit'])

      yield(metric_details['id'], attributes)
    end

    def find_or_build_metric!(id)
      raise MissingQueryId unless id

      PrometheusMetric.common.find_by(identifier: id) ||
        PrometheusMetric.new(common: true, identifier: id)
    end

    def find_group_title_key(title)
      PrometheusMetric.groups[find_group_title(title)]
    end

    def find_group_title(title)
      PrometheusMetric::GROUP_TITLES.invert[title]
    end
  end
end
