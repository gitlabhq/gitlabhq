# frozen_string_literal: true

module Users
  class PinsController < ApplicationController
    include Gitlab::InternalEventsTracking

    feature_category :navigation
    respond_to :json

    before_action :check_request_size, only: :update

    def update
      panel = pins_params[:panel]
      new_menu_items = pins_params[:menu_item_ids]
      prev_menu_items = current_user.pinned_nav_items[panel] || []

      pinned_nav_items = current_user.pinned_nav_items.merge({ panel => new_menu_items })

      if current_user.update(pinned_nav_items: pinned_nav_items)
        track_nav_item_change(panel, new_menu_items, prev_menu_items)
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

    def track_nav_item_change(panel, new_menu_items, prev_menu_items)
      removed_item = prev_menu_items - new_menu_items
      added_item = new_menu_items - prev_menu_items

      track_unpin_event(panel, removed_item.first) if removed_item.present?
      track_pin_event(panel, added_item.first) if added_item.present?
    end

    def track_unpin_event(panel, item)
      track_internal_event(
        "unpin_nav_item_from_sidebar",
        user: current_user,
        additional_properties: {
          label: panel,
          property: item
        }
      )
    end

    def track_pin_event(panel, item)
      track_internal_event(
        "pin_nav_item_on_sidebar",
        user: current_user,
        additional_properties: {
          label: panel,
          property: item
        }
      )
    end
  end
end
