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

  def ssh_key_delete_modal_data(key, is_admin)
    {
        path: path_to_key(key, is_admin),
        method: 'delete',
        qa_selector: 'delete_ssh_key_button',
        modal_attributes: {
            'data-qa-selector': 'ssh_key_delete_modal',
            title: _('Are you sure you want to delete this SSH key?'),
            message: _('This action cannot be undone, and will permanently delete the %{key} SSH key') % { key: key.title },
            okVariant: 'danger',
            okTitle: _('Delete')
        }
    }
  end
end
