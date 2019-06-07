# frozen_string_literal: true

class Profiles::AccountsController < Profiles::ApplicationController
  include AuthHelper

  def show
    render(locals: show_view_variables)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def unlink
    provider = params[:provider]
    identity = current_user.identities.find_by(provider: provider)

    return render_404 unless identity

    if unlink_provider_allowed?(provider)
      identity.destroy
    else
      flash[:alert] = _("You are not allowed to unlink your primary login account")
    end

    redirect_to profile_account_path
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def show_view_variables
    {}
  end
end
