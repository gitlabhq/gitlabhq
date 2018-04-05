class Admin::DevOpsScoreController < Admin::ApplicationController
  def show
    @metric = DevOpsScore::Metric.order(:created_at).last&.present
  end
end
