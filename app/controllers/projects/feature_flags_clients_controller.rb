# frozen_string_literal: true

class Projects::FeatureFlagsClientsController < Projects::ApplicationController
  before_action :authorize_admin_feature_flags_client!
  before_action :feature_flags_client

  feature_category :feature_flags
  urgency :low

  def reset_token
    feature_flags_client.reset_token!

    respond_to do |format|
      format.json do
        render json: feature_flags_client_token_json, status: :ok
      end
    end
  end

  private

  def feature_flags_client
    project.operations_feature_flags_client || not_found
  end

  def feature_flags_client_token_json
    FeatureFlagsClientSerializer.new
      .represent_token(feature_flags_client)
  end
end
