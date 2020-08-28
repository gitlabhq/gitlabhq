# frozen_string_literal: true

class Admin::InstanceStatisticsController < Admin::ApplicationController
  before_action :check_feature_flag

  def index
  end

  def check_feature_flag
    render_404 unless Feature.enabled?(:instance_analytics)
  end
end
