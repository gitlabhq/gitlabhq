class Groups::OmniauthCallbacksController < OmniauthCallbacksController
  extend ::Gitlab::Utils::Override

  skip_before_action :verify_authenticity_token, only: [:failure, :group_saml]

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

  override :find_message
  def find_message(kind, options = {})
    _('Unable to sign you in to the group with SAML due to "%{reason}"') % options
  end

  override :after_omniauth_failure_path_for
  def after_omniauth_failure_path_for(scope)
    group_saml_failure_path(scope)
  end

  def group_saml_failure_path(scope)
    group = Gitlab::Auth::GroupSaml::GroupLookup.new(request.env).group

    unless can?(current_user, :sign_in_with_saml_provider, group&.saml_provider)
      OmniAuth::Strategies::GroupSaml.invalid_group!(group&.path)
    end

    if can?(current_user, :admin_group_saml, group)
      group_saml_providers_path(group)
    else
      sso_group_saml_providers_path(group)
    end
  end
end
