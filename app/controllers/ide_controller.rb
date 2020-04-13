# frozen_string_literal: true

class IdeController < ApplicationController
  layout 'fullscreen'

  include ClientsidePreviewCSP
  include StaticObjectExternalStorageCSP

  before_action do
    push_frontend_feature_flag(:webide_dark_theme)
  end

  def index
    Gitlab::UsageDataCounters::WebIdeCounter.increment_views_count
  end
end

IdeController.prepend_if_ee('EE::IdeController')
