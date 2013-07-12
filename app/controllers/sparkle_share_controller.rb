class SparkleShareController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :get_invite

  # SparkleShare application downloads the invite.xml file
  def invite

  end

  # SparkleShare application posts its public key
  def accept_invite
    if @invite.accept!(posted_public_key)
      render nothing: true, status: :ok
    else
      render nothing: true, status: :forbidden
    end
  end

  private
  def get_invite
    @invite = SparkleInvite.find_by_token(params[:token])
    raise ActiveRecord::RecordNotFound unless @invite
  end

  def posted_public_key
    # Fix incorrect spaces in the public key by replacing them with +'s
    parts = params[:public_key].split
    first, last = parts.shift, parts.pop
    "#{first} #{parts.join('+')} #{last}"
  end
end
