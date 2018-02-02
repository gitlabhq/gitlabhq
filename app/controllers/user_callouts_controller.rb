class UserCalloutsController < ApplicationController
  def create
    if ensure_callout
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

  def ensure_callout
    current_user.callouts.find_or_create_by(feature_name: callout_param)
  end

  def callout_param
    params.require(:feature_name)
  end
end
