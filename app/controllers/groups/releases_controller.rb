# frozen_string_literal: true

module Groups
  class ReleasesController < Groups::ApplicationController
    feature_category :release_evidence
    urgency :low

    def index
      respond_to do |format|
        format.json do
          render json: ReleaseSerializer.new.represent(releases)
        end
      end
    end

    private

    def releases
      Releases::GroupReleasesFinder
        .new(@group, current_user)
        .execute(preload: false)
        .page(pagination_params[:page])
        .per(30)
    end
  end
end
