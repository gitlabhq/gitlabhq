module EE
  module SamlProvidersHelper
    def group_saml_enabled?
      group_saml_beta_enabled? && ::Gitlab::Auth::GroupSaml::Config.enabled?
    end

    def group_saml_beta_enabled?
      ::Gitlab::Utils.to_boolean(cookies['enable_group_saml'])
    end

    def show_saml_in_sidebar?(group)
      group_saml_enabled? && !group.subgroup? && can?(current_user, :admin_group_saml, group)
    end

    def saml_link(text, group_path, redirect: nil, html_class: 'btn')
      redirect ||= group_path(group_path)
      url = omniauth_authorize_path(:user, :group_saml, group_path: group_path, redirect_to: redirect)

      link_to(text, url, method: :post, class: html_class)
    end
  end
end
