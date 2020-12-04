# frozen_string_literal: true

class WhatsNewController < ApplicationController
  skip_before_action :authenticate_user!

  before_action :check_feature_flag, :check_valid_page_param, :set_pagination_headers

  feature_category :navigation

  def index
    respond_to do |format|
      format.js do
        render json: most_recent_items
      end
    end
  end

  private

  def check_feature_flag
    render_404 unless Feature.enabled?(:whats_new_drawer, current_user)
  end

  def check_valid_page_param
    render_404 if current_page < 1
  end

  def current_page
    params[:page]&.to_i || 1
  end

  def most_recent
    @most_recent ||= ReleaseHighlight.paginated(page: current_page)
  end

  def most_recent_items
    most_recent[:items].map {|item| Gitlab::WhatsNew::ItemPresenter.present(item) }
  end

  def set_pagination_headers
    response.set_header('X-Next-Page', most_recent[:next_page])
  end
end
