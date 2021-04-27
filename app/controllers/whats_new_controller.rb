# frozen_string_literal: true

class WhatsNewController < ApplicationController
  include Gitlab::Utils::StrongMemoize

  skip_before_action :authenticate_user!

  before_action :check_whats_new_enabled
  before_action :check_valid_page_param, :set_pagination_headers

  feature_category :navigation

  def index
    respond_to do |format|
      format.js do
        render json: highlights.items
      end
    end
  end

  private

  def check_whats_new_enabled
    render_404 if Gitlab::CurrentSettings.current_application_settings.whats_new_variant_disabled?
  end

  def check_valid_page_param
    render_404 if current_page < 1
  end

  def current_page
    params[:page]&.to_i || 1
  end

  def highlights
    strong_memoize(:highlights) do
      ReleaseHighlight.paginated(page: current_page)
    end
  end

  def set_pagination_headers
    response.set_header('X-Next-Page', highlights.next_page)
  end
end
