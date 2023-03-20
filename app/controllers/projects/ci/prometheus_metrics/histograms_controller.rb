# frozen_string_literal: true

module Projects
  module Ci
    module PrometheusMetrics
      class HistogramsController < Projects::ApplicationController
        feature_category :pipeline_composition

        respond_to :json, only: [:create]

        def create
          result = ::Ci::PrometheusMetrics::ObserveHistogramsService.new(project, permitted_params).execute

          render json: result.payload, status: result.http_status
        end

        private

        def permitted_params
          params.permit(histograms: [:name, :value])
        end
      end
    end
  end
end
