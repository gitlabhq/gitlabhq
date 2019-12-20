# frozen_string_literal: true

class Projects::Environments::SampleMetricsController < Projects::ApplicationController
  def query
    result = Metrics::SampleMetricsService.new(params[:identifier]).query

    if result
      render json: { "status": "success", "data": { "resultType": "matrix", "result": result } }
    else
      render_404
    end
  end
end
