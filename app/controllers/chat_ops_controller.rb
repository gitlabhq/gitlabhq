class ChatOpsController < ApplicationController
  respond_to :json

  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def trigger
    render json: { ok: true }
  end
end
