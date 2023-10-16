# frozen_string_literal: true

module Users
  class NamespaceVisitsController < ApplicationController
    feature_category :navigation

    def create
      return head :bad_request unless params[:type].present? && params[:id].present?

      Users::TrackNamespaceVisitsWorker.perform_async(params[:type], params[:id], current_user.id, DateTime.now) # rubocop:disable CodeReuse/Worker
      head :ok
    end
  end
end
