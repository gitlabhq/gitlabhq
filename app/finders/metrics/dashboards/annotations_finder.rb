# frozen_string_literal: true

module Metrics
  module Dashboards
    class AnnotationsFinder
      def initialize(dashboard:, params:)
        @dashboard = dashboard
        @params = params
      end

      def execute
        if dashboard.environment
          apply_filters_to(annotations_for_environment)
        else
          Metrics::Dashboard::Annotation.none
        end
      end

      private

      attr_reader :dashboard, :params

      def apply_filters_to(annotations)
        annotations = annotations.after(params[:from]) if params[:from].present?
        annotations = annotations.before(params[:to]) if params[:to].present? && valid_timespan_boundaries?

        by_dashboard(annotations)
      end

      def annotations_for_environment
        dashboard.environment.metrics_dashboard_annotations
      end

      def by_dashboard(annotations)
        annotations.for_dashboard(dashboard.path)
      end

      def valid_timespan_boundaries?
        params[:from].blank? || params[:to] >= params[:from]
      end
    end
  end
end
