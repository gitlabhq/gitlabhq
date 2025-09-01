# frozen_string_literal: true

class WhatsNewController < ApplicationController
  include Gitlab::Utils::StrongMemoize

  skip_before_action :authenticate_user!, only: :index

  before_action :check_whats_new_enabled
  before_action :check_valid_page_param, :set_pagination_headers, only: :index

  feature_category :onboarding
  urgency :low

  def index
    respond_to do |format|
      format.js do
        render json: highlights.items
      end
    end
  end

  def mark_as_read
    result = article_read_status_service.mark_article_as_read(mark_as_read_params[:article_id])

    if result.success?
      head :ok
    else
      render json: result.message, status: :bad_request
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
    pagination_params[:page]&.to_i || 1
  end

  def highlights
    strong_memoize(:highlights) do
      ReleaseHighlight.paginated(page: current_page)
    end
  end

  def set_pagination_headers
    response.set_header('X-Next-Page', highlights.next_page)
  end

  def mark_as_read_params
    params.permit(:article_id)
  end

  def article_read_status_service
    Onboarding::WhatsNew::ReadStatusService.new(current_user.id, ReleaseHighlight.most_recent_version_digest)
  end
end
