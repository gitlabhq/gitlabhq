# frozen_string_literal: true

module SshKeysHelper
  def ssh_key_delete_modal_data(key, path)
    title = _('Delete Key')

    {
      path: path,
      method: 'delete',
      testid: 'delete-ssh-key-button',
      title: title,
      aria_label: title,
      modal_attributes: {
        'data-testid': 'ssh-key-delete-modal',
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

  def ssh_key_revoke_modal_data(key, path)
    title = _('Revoke Key')

    {
      path: path,
      method: 'delete',
      title: title,
      aria_label: title,
      modal_attributes: {
        title: _('Are you sure you want to revoke this SSH key?'),
        message: _('This action cannot be undone, and will permanently delete the %{key} SSH key. All commits ' \
          'signed using this SSH key will be marked as unverified.') % { key: key.title },
        okVariant: 'danger',
        okTitle: _('Revoke')
      },
      toggle: 'tooltip',
      placement: 'top',
      container: 'body'
    }
  end

  def ssh_key_allowed_algorithms
    allowed_algorithms = Gitlab::CurrentSettings.allowed_key_types.flat_map do |type|
      tech = Gitlab::SSHPublicKey.technology(type)
      restriction = Gitlab::CurrentSettings.key_restriction_for(type)

      if restriction > 0 && tech.supported_sizes.length == tech.supported_algorithms.length
        tech.supported_sizes.zip(tech.supported_algorithms)
            .select { |size, _| size >= restriction }
            .map(&:last)
      else
        tech.supported_algorithms
      end
    end

    quoted_allowed_algorithms = allowed_algorithms.map { |name| "'#{name}'" }

    Gitlab::Sentence.to_exclusive_sentence(quoted_allowed_algorithms)
  end
end
