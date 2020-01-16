# frozen_string_literal: true

class IdeController < ApplicationController
  layout 'fullscreen'

  before_action do
    push_frontend_feature_flag(:stage_all_by_default, default_enabled: true)
  end

  def index
    Gitlab::UsageDataCounters::WebIdeCounter.increment_views_count
  end
end

IdeController.prepend_if_ee('EE::IdeController')
