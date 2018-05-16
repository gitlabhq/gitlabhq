class Groups::OmniauthCallbacksController < OmniauthCallbacksController
  extend ::Gitlab::Utils::Override

  skip_before_filter :verify_authenticity_token, only: :group_saml

  def group_saml
    @unauthenticated_group = Group.find_by_full_path(params[:group_id])
    saml_provider = @unauthenticated_group.saml_provider

    identity_linker = Gitlab::Auth::GroupSaml::IdentityLinker.new(current_user, oauth, saml_provider)

    omniauth_flow(Gitlab::Auth::GroupSaml, identity_linker: identity_linker)
  end

  private

  override :redirect_identity_linked
  def redirect_identity_linked
    flash[:notice] = "SAML for #{@unauthenticated_group.name} was added to your connected accounts"

    redirect_to after_sign_in_path_for(current_user)
  end

  override :redirect_identity_exists
  def redirect_identity_exists
    flash[:notice] = "Signed in with SAML for #{@unauthenticated_group.name}"

    redirect_to after_sign_in_path_for(current_user)
  end

  override :after_sign_in_path_for
  def after_sign_in_path_for(resource)
    saml_redirect_path || super
  end

  override :sign_in_user_flow
  def sign_in_user_flow(auth_user_class)
    # User has successfully authenticated with the SAML provider for the group
    # but is not signed in to the GitLab instance.

    flash[:notice] = "You must be signed in to use SAML with this group"

    redirect_to new_user_session_path
  end

  def saml_redirect_path
    params['RelayState'].presence if current_user
  end
end
