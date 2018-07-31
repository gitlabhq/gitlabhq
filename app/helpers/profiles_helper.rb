module ProfilesHelper
  def attribute_provider_label(attribute)
    user_synced_attributes_metadata = current_user.user_synced_attributes_metadata
    if user_synced_attributes_metadata&.synced?(attribute)
      if user_synced_attributes_metadata.provider
        Gitlab::Auth::OAuth::Provider.label_for(user_synced_attributes_metadata.provider)
      else
        'LDAP'
      end
    end
  end
end
