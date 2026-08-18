# frozen_string_literal: true

module Onboarding
  class FeatureLibraryController < ApplicationController
    feature_category :onboarding
    urgency :low

    MAX_QUERY_LENGTH = 255

    before_action :check_feature_library_search_rate_limit!, only: :search

    before_action :check_feature_library_ai_search_rate_limit!,
      only: :ai_search,
      if: -> { feature_match_service.ai_search_enabled? }

    def search
      return render json: { ids: [] } unless valid_panel?

      render json: { ids: feature_match_service.execute }
    end

    def ai_search
      return not_found unless feature_match_service.ai_search_enabled?
      return render json: { ids: [], ai_search_available: false } unless valid_panel?
      return render json: { ids: [], ai_search_available: false } unless feature_match_service.ai_search_available?

      render json: { ids: feature_match_service.ai_execute, ai_search_available: true }
    end

    private

    def feature_match_service
      @feature_match_service ||= Onboarding::FeatureLibrary::FeatureMatchService.new(
        query: truncated_query,
        panel: search_params[:panel],
        user: current_user,
        resource: resource
      )
    end

    def search_params
      params.permit(:query, :panel, :resource_id)
    end

    def resource
      resource_id = search_params[:resource_id]
      return unless resource_id

      if search_params[:panel] == 'group'
        resource = Group.find_by_id(resource_id)
        ability = :read_group
      else
        resource = Project.find_by_id(resource_id)
        ability = :read_project
      end

      resource if resource && can?(current_user, ability, resource)
    end

    def valid_panel?
      Onboarding::FeatureLibrary::FeatureMatchService::VALID_PANELS.include?(search_params[:panel])
    end

    def truncated_query
      search_params[:query].to_s.first(MAX_QUERY_LENGTH)
    end

    def check_feature_library_search_rate_limit!
      check_rate_limit!(:feature_library_search, scope: current_user) do
        render json: { error: _('This endpoint has been requested too many times. Try again later.') },
          status: :too_many_requests
      end
    end

    def check_feature_library_ai_search_rate_limit!
      check_rate_limit!(:feature_library_ai_search, scope: current_user) do
        render json: { error: _('This endpoint has been requested too many times. Try again later.') },
          status: :too_many_requests
      end
    end
  end
end
