# frozen_string_literal: true

class IdeController < ApplicationController
  layout 'fullscreen'

  def index
    Gitlab::UsageDataCounters::WebIdeCounter.increment_views_count
  end
end
