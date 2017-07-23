module ProfilesHelper
  def email_provider_label
    return unless current_user.external_email?

    current_user.email_provider.present? ? Gitlab::OAuth::Provider.label_for(current_user.email_provider) : "LDAP"
  end
end
