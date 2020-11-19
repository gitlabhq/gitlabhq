# frozen_string_literal: true

class WhatsNewController < ApplicationController
  include Gitlab::WhatsNew

  skip_before_action :authenticate_user!

  before_action :check_feature_flag, :check_valid_page_param, :set_pagination_headers

  feature_category :navigation

  def index
    respond_to do |format|
      format.js do
        render json: whats_new_release_items(page: current_page)
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

  def set_pagination_headers
    response.set_header('X-Next-Page', next_page)
  end

  def current_page
    params[:page]&.to_i || 1
  end

  def next_page
    next_page = current_page + 1
    next_index = next_page - 1

    next_page if whats_new_file_paths[next_index]
  end
end
