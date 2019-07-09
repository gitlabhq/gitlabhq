# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module CommonMetrics
      class Importer
        MissingQueryId = Class.new(StandardError)

        attr_reader :content

        def initialize(filename = 'common_metrics.yml')
          @content = YAML.load_file(Rails.root.join('config', 'prometheus', filename))
        end

        def execute
          CommonMetrics::PrometheusMetric.reset_column_information

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

        # rubocop: disable CodeReuse/ActiveRecord
        def find_or_build_metric!(id)
          raise MissingQueryId unless id

          CommonMetrics::PrometheusMetric.common.find_by(identifier: id) ||
            CommonMetrics::PrometheusMetric.new(common: true, identifier: id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def find_group_title_key(title)
          CommonMetrics::PrometheusMetricEnums.groups[find_group_title(title)]
        end

        def find_group_title(title)
          CommonMetrics::PrometheusMetricEnums.group_titles.invert[title]
        end
      end
    end
  end
end
