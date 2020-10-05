# frozen_string_literal: true

class UserCalloutsController < ApplicationController
  feature_category :navigation

  def create
    callout = ensure_callout

    if callout.persisted?
      callout.update(dismissed_at: Time.current)
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

  # rubocop: disable CodeReuse/ActiveRecord
  def ensure_callout
    current_user.callouts.find_or_create_by(feature_name: UserCallout.feature_names[feature_name])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def feature_name
    params.require(:feature_name)
  end
end
