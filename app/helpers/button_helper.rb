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
    title = data[:title] || 'Copy to clipboard'
    button_text = data[:button_text] || ''
    hide_tooltip = data[:hide_tooltip] || false
    hide_button_icon = data[:hide_button_icon] || false

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
      aria: { label: title }
    }

    content_tag :button, button_attributes do
      concat(icon('clipboard', 'aria-hidden': 'true')) unless hide_button_icon
      concat(button_text)
    end
  end

  def http_clone_button(project, append_link: true)
    protocol = gitlab_config.protocol.upcase
    dropdown_description = http_dropdown_description(protocol)
    append_url = project.http_url_to_repo if append_link

    dropdown_item_with_description(protocol, dropdown_description, href: append_url)
  end

  def http_dropdown_description(protocol)
    if current_user.try(:require_password_creation_for_git?)
      _("Set a password on your account to pull or push via %{protocol}.") % { protocol: protocol }
    else
      _("Create a personal access token on your account to pull or push via %{protocol}.") % { protocol: protocol }
    end
  end

  def ssh_clone_button(project, append_link: true)
    dropdown_description = _("You won't be able to pull or push project code via SSH until you add an SSH key to your profile") if current_user.try(:require_ssh_key?)
    append_url = project.ssh_url_to_repo if append_link

    dropdown_item_with_description('SSH', dropdown_description, href: append_url)
  end

  def dropdown_item_with_description(title, description, href: nil)
    button_content = content_tag(:strong, title, class: 'dropdown-menu-inner-title')
    button_content << content_tag(:span, description, class: 'dropdown-menu-inner-content') if description

    content_tag (href ? :a : :span),
      (href ? button_content : title),
      class: "#{title.downcase}-selector",
      href: (href if href)
  end
end
