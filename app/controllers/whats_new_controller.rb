# frozen_string_literal: true

class WhatsNewController < ApplicationController
  include Gitlab::WhatsNew

  skip_before_action :authenticate_user!

  before_action :check_feature_flag

  feature_category :navigation

  def index
    respond_to do |format|
      format.js do
        render json: whats_new_most_recent_release_items
      end
    end
  end

  private

  def check_feature_flag
    render_404 unless Feature.enabled?(:whats_new_drawer, current_user)
  end
end
