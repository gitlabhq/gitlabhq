# frozen_string_literal: true

class Admin::VersionCheckController < Admin::ApplicationController
  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

  def version_check
    response = VersionCheck.new.response

    expires_in 1.minute if response
    render json: response
  end
end
