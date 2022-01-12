# frozen_string_literal: true

module SshKeysHelper
  def ssh_key_delete_modal_data(key, path)
    {
        path: path,
        method: 'delete',
        qa_selector: 'delete_ssh_key_button',
        modal_attributes: {
            'data-qa-selector': 'ssh_key_delete_modal',
            title: _('Are you sure you want to delete this SSH key?'),
            message: _('This action cannot be undone, and will permanently delete the %{key} SSH key') % { key: key.title },
            okVariant: 'danger',
            okTitle: _('Delete')
        },
        toggle: 'tooltip',
        placement: 'top',
        container: 'body'
    }
  end

  def ssh_key_allowed_algorithms
    allowed_algorithms = Gitlab::CurrentSettings.allowed_key_types.flat_map do |ssh_key_type_name|
      Gitlab::SSHPublicKey.supported_algorithms_for_name(ssh_key_type_name)
    end

    quoted_allowed_algorithms = allowed_algorithms.map { |name| "'#{name}'" }

    Gitlab::Utils.to_exclusive_sentence(quoted_allowed_algorithms)
  end
end
