# frozen_string_literal: true

class Profiles::AccountsController < Profiles::ApplicationController
  include AuthHelper

  feature_category :system_access
  urgency :low, [:show]

  def show
    push_frontend_feature_flag(:delay_delete_own_user)
    render(locals: show_view_variables)
  end

  def unlink
    provider = params[:provider]
    identity = find_identity(provider)

    return render_404 unless identity

    if unlink_provider_allowed?(provider)
      identity.destroy
    else
      flash[:alert] = _("You are not allowed to unlink your primary login account")
    end

    redirect_to profile_account_path
  end

  private

  def show_view_variables
    {}
  end

  def find_identity(provider)
    return current_user.atlassian_identity if provider == 'atlassian_oauth2'

    current_user.identities.find_by(provider: provider) # rubocop: disable CodeReuse/ActiveRecord
  end
end

Profiles::AccountsController.prepend_mod_with('Profiles::AccountsController')
