# frozen_string_literal: true

class Admin::UsageTrendsController < Admin::ApplicationController
  include RedisTracking

  track_redis_hll_event :index, name: 'i_analytics_instance_statistics'

  feature_category :devops_reports

  urgency :low

  def index
  end
end
