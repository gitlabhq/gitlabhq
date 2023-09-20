# frozen_string_literal: true

module Users
  class NamespaceVisitsController < ApplicationController
    feature_category :navigation

    def create
      return head :not_found unless Feature.enabled?(:server_side_frecent_namespaces, current_user)
      return head :bad_request unless params[:type].present? && params[:id].present?

      Users::TrackNamespaceVisitsWorker.perform_async(params[:type], params[:id], current_user.id, DateTime.now) # rubocop:disable CodeReuse/Worker
      head :ok
    end
  end
end
