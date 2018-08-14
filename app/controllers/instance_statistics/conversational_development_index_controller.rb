# frozen_string_literal: true

class InstanceStatistics::ConversationalDevelopmentIndexController < InstanceStatistics::ApplicationController
  def index
    @metric = ConversationalDevelopmentIndex::Metric.order(:created_at).last&.present
  end
end
