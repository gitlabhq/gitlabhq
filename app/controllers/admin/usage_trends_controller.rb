# frozen_string_literal: true

class Admin::UsageTrendsController < Admin::ApplicationController
  include Analytics::UniqueVisitsHelper

  track_unique_visits :index, target_id: 'i_analytics_instance_statistics'

  feature_category :devops_reports

  def index
  end
end
