# frozen_string_literal: true

class WhatsNewController < ApplicationController
  include Gitlab::Utils::StrongMemoize

  skip_before_action :authenticate_user!

  before_action :check_valid_page_param, :set_pagination_headers, unless: -> { has_version_param? }

  feature_category :navigation

  def index
    respond_to do |format|
      format.js do
        render json: highlight_items
      end
    end
  end

  private

  def check_valid_page_param
    render_404 if current_page < 1
  end

  def current_page
    params[:page]&.to_i || 1
  end

  def highlights
    strong_memoize(:highlights) do
      if has_version_param?
        ReleaseHighlight.for_version(version: params[:version])
      else
        ReleaseHighlight.paginated(page: current_page)
      end
    end
  end

  def highlight_items
    highlights.map {|item| Gitlab::WhatsNew::ItemPresenter.present(item) }
  end

  def set_pagination_headers
    response.set_header('X-Next-Page', highlights.next_page)
  end

  def has_version_param?
    params[:version].present?
  end
end
