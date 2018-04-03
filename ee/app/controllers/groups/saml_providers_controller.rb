class Groups::SamlProvidersController < Groups::ApplicationController
  before_action :require_top_level_group
  before_action :authorize_manage_saml!
  before_action :check_group_saml_available!
  before_action :check_group_saml_configured
  before_action :check_group_saml_beta_enabled

  def show
    @saml_provider = @group.saml_provider || @group.build_saml_provider
  end

  def create
    @saml_provider = @group.build_saml_provider(saml_provider_params)

    @saml_provider.save

    render :show
  end

  def update
    @saml_provider = @group.saml_provider

    @saml_provider.update(saml_provider_params)

    render :show
  end

  private

  def authorize_manage_saml!
    render_404 unless can?(current_user, :admin_group_saml, @group)
  end

  def check_group_saml_configured
    render_404 unless Gitlab::Auth::GroupSaml::Config.enabled?
  end

  def check_group_saml_beta_enabled
    render_404 unless Gitlab::Utils.to_boolean(cookies['enable_group_saml'])
  end

  def require_top_level_group
    render_404 if @group.subgroup?
  end

  def saml_provider_params
    allowed_params = %i[sso_url certificate_fingerprint enabled]
    params.require(:saml_provider).permit(allowed_params)
  end
end
