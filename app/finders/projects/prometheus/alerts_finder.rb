# frozen_string_literal: true

module Projects
  module Prometheus
    # Find Prometheus alerts by +project+, +environment+, +id+,
    # or any combo thereof.
    #
    # Optionally filter by +metric+.
    #
    # Arguments:
    #   params:
    #     project: Project | integer
    #     environment: Environment | integer
    #     metric: PrometheusMetric | integer
    class AlertsFinder
      def initialize(params = {})
        unless params[:project] || params[:environment] || params[:id]
          raise ArgumentError,
            'Please provide one or more of the following params: :project, :environment, :id'
        end

        @params = params
      end

      # Find all matching alerts
      #
      # @return [ActiveRecord::Relation<PrometheusAlert>]
      def execute
        relation = by_project(PrometheusAlert)
        relation = by_environment(relation)
        relation = by_metric(relation)
        relation = by_id(relation)
        ordered(relation)
      end

      private

      attr_reader :params

      def by_project(relation)
        return relation unless params[:project]

        relation.for_project(params[:project])
      end

      def by_environment(relation)
        return relation unless params[:environment]

        relation.for_environment(params[:environment])
      end

      def by_metric(relation)
        return relation unless params[:metric]

        relation.for_metric(params[:metric])
      end

      def by_id(relation)
        return relation unless params[:id]

        relation.id_in(params[:id])
      end

      def ordered(relation)
        relation.order_by('id_asc')
      end
    end
  end
end
