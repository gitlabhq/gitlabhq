# frozen_string_literal: true

module Organizations
  class ArtifactRegistryController < ApplicationController
    feature_category :organization

    before_action :authorize_read_artifact_registry!

    def index; end

    private

    def authorize_read_artifact_registry!
      access_denied! unless can?(current_user, :read_artifact_registry, organization)
    end
  end
end
