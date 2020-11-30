# frozen_string_literal: true

module ProfilesHelper
  def commit_email_select_options(user)
    private_email = user.private_commit_email
    verified_emails = user.verified_emails - [private_email]

    [
      [s_("Profiles|Use a private email - %{email}").html_safe % { email: private_email }, Gitlab::PrivateCommitEmail::TOKEN],
      *verified_emails
    ]
  end

  def selected_commit_email(user)
    user.read_attribute(:commit_email) || user.commit_email
  end

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

  def user_profile?
    params[:controller] == 'users'
  end

  def availability_values
    Types::AvailabilityEnum.enum
  end

  def user_status_set_to_busy?(status)
    status&.availability == availability_values[:busy]
  end
end
