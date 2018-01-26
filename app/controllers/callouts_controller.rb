class CalloutsController < ApplicationController
  before_action :callout, only: [:dismiss]

  def dismiss
    respond_to do |format|
      format.json do
        if @callout
          @callout.update(dismissed_state: true)
        else
          Callout.create(feature_name: callout_param, dismissed_state: true, user: current_user)
        end

        head :ok
      end
    end
  end

  private

  def callout
    @callout = Callout.find_by(user: current_user, feature_name: callout_param)
  end

  def callout_param
    params.require(:feature_name)
  end
end
