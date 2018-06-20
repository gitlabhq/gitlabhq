module EE
  module SamlProvidersHelper
    def group_saml_configured?
      ::Gitlab::Auth::GroupSaml::Config.enabled?
    end

    def show_saml_in_sidebar?(group)
      return false unless group_saml_configured?
      return false unless group.feature_available?(:group_saml)
      return false if group.subgroup?

      can?(current_user, :admin_group_saml, group)
    end

    def saml_link_for_provider(text, provider, *args)
      saml_link(text, provider.group.full_path, *args)
    end

    def saml_link(text, group_path, redirect: nil, html_class: 'btn')
      redirect ||= group_path(group_path)
      url = omniauth_authorize_path(:user, :group_saml, group_path: group_path, redirect_to: redirect)

      link_to(text, url, method: :post, class: html_class)
    end
  end
end
