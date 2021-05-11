# frozen_string_literal: true

module ButtonHelper
  # Output a "Copy to Clipboard" button
  #
  # data  - Data attributes passed to `content_tag` (default: {}):
  #         :text   - Text to copy (optional)
  #         :gfm    - GitLab Flavored Markdown to copy, if different from `text` (optional)
  #         :target - Selector for target element to copy from (optional)
  #
  # Examples:
  #
  #   # Define the clipboard's text
  #   clipboard_button(text: "Foo")
  #   # => "<button class='...' data-clipboard-text='Foo'>...</button>"
  #
  #   # Define the target element
  #   clipboard_button(target: "div#foo")
  #   # => "<button class='...' data-clipboard-target='div#foo'>...</button>"
  #
  # See http://clipboardjs.com/#usage
  def clipboard_button(data = {})
    css_class = data[:class] || 'btn-clipboard btn-transparent'
    title = data[:title] || _('Copy')
    button_text = data[:button_text] || ''
    hide_tooltip = data[:hide_tooltip] || false
    hide_button_icon = data[:hide_button_icon] || false
    item_prop = data[:itemprop] || nil

    # This supports code in app/assets/javascripts/copy_to_clipboard.js that
    # works around ClipboardJS limitations to allow the context-specific copy/pasting of plain text or GFM.
    if text = data.delete(:text)
      data[:clipboard_text] =
        if gfm = data.delete(:gfm)
          { text: text, gfm: gfm }
        else
          text
        end
    end

    target = data.delete(:target)
    data[:clipboard_target] = target if target

    unless hide_tooltip
      data = { toggle: 'tooltip', placement: 'bottom', container: 'body' }.merge(data)
    end

    button_attributes = {
      class: "btn #{css_class}",
      data: data,
      type: :button,
      title: title,
      aria: { label: title },
      itemprop: item_prop
    }

    content_tag :button, button_attributes do
      concat(sprite_icon('copy-to-clipboard')) unless hide_button_icon
      concat(button_text)
    end
  end

  def http_clone_button(container, append_link: true)
    protocol = gitlab_config.protocol.upcase
    dropdown_description = http_dropdown_description(protocol)
    append_url = container.http_url_to_repo if append_link

    dropdown_item_with_description(protocol, dropdown_description, href: append_url, data: { clone_type: 'http' })
  end

  def http_dropdown_description(protocol)
    if current_user.try(:require_password_creation_for_git?)
      _("Set a password on your account to pull or push via %{protocol}.") % { protocol: protocol }
    elsif current_user.try(:require_personal_access_token_creation_for_git_auth?)
      _("Create a personal access token on your account to pull or push via %{protocol}.") % { protocol: protocol }
    end
  end

  def ssh_clone_button(container, append_link: true)
    if Gitlab::CurrentSettings.user_show_add_ssh_key_message? &&
        current_user.try(:require_ssh_key?)
      dropdown_description = s_("MissingSSHKeyWarningLink|You won't be able to pull or push repositories via SSH until you add an SSH key to your profile")
    end

    append_url = container.ssh_url_to_repo if append_link

    dropdown_item_with_description('SSH', dropdown_description, href: append_url, data: { clone_type: 'ssh' })
  end

  def dropdown_item_with_description(title, description, href: nil, data: nil, default: false)
    active_class = "is-active" if default
    button_content = content_tag(:strong, title, class: 'dropdown-menu-inner-title')
    button_content << content_tag(:span, description, class: 'dropdown-menu-inner-content') if description

    content_tag (href ? :a : :span),
      (href ? button_content : title),
      class: "#{title.downcase}-selector #{active_class}",
      href: href,
      data: data
  end
end

ButtonHelper.prepend_mod_with('ButtonHelper')
