# frozen_string_literal: true

class Admin::InstanceStatisticsController < Admin::ApplicationController
  include Analytics::UniqueVisitsHelper

  before_action :check_feature_flag

  track_unique_visits :index, target_id: 'i_analytics_instance_statistics'

  feature_category :devops_reports

  def index
  end

  def check_feature_flag
    render_404 unless Feature.enabled?(:instance_statistics, default_enabled: true)
  end
end
