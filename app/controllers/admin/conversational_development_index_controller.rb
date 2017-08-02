class Admin::ConversationalDevelopmentIndexController < Admin::ApplicationController
  def show
    @metric = ConversationalDevelopmentIndex::Metric.order(:created_at).last&.present
  end
end
