# frozen_string_literal: true

class KeyPresenter < Gitlab::View::Presenter::Delegated # rubocop:disable Gitlab/NamespacedClass
  include SafeFormatHelper

  presents ::Key, as: :key_object

  def humanized_error_message(type: :key)
    if !key_object.public_key.valid?
      help_link = help_page_link(_('supported SSH public key.'), 'user/ssh', 'supported-ssh-key-types')

      safe_format(_('%{type} must be a %{help_link}'), type: type.to_s.humanize, help_link: help_link)
    else
      key_object.errors.full_messages.join(', ').html_safe
    end
  end

  private

  def help_page_link(title, path, anchor)
    ActionController::Base.helpers.link_to(title, help_page_path(path, anchor: anchor),
      target: '_blank', rel: 'noopener noreferrer')
  end
end
