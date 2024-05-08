# frozen_string_literal: true

module Users
  class PinsController < ApplicationController
    feature_category :navigation
    respond_to :json

    before_action :check_request_size, only: :update

    def update
      panel = pins_params[:panel]
      pinned_nav_items = current_user.pinned_nav_items.merge({ panel => pins_params[:menu_item_ids] })
      if current_user.update(pinned_nav_items: pinned_nav_items)
        render json: current_user.pinned_nav_items[panel].to_json
      else
        head :bad_request
      end
    end

    private

    def pins_params
      params.permit(:panel, menu_item_ids: [])
    end

    def check_request_size
      return if params.to_s.bytesize < 100.kilobytes

      head :payload_too_large
    end
  end
end
