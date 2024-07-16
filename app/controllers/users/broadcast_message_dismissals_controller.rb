# frozen_string_literal: true

module Users
  class BroadcastMessageDismissalsController < ApplicationController
    feature_category :notifications
    urgency :low

    def create
      if service_response.success?
        respond_to do |format|
          format.json { head :ok }
        end
      else
        respond_to do |format|
          format.json { head :bad_request }
        end
      end
    end

    private

    def broadcast_message_id
      params.require(:broadcast_message_id)
    end

    def expires_at
      params.require(:expires_at)
    end

    def service_response
      Users::DismissBroadcastMessageService.new(current_user: current_user,
        params: { broadcast_message_id: broadcast_message_id, expires_at: expires_at }).execute
    end
  end
end
