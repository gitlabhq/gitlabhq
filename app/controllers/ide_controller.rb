# frozen_string_literal: true

class IdeController < ApplicationController
  layout 'fullscreen'

  include ClientsidePreviewCSP
  include StaticObjectExternalStorageCSP

  before_action do
    push_frontend_feature_flag(:build_service_proxy)
  end

  def index
    Gitlab::UsageDataCounters::WebIdeCounter.increment_views_count
  end
end
