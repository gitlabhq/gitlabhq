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

  def http_clone_button(project, placement = 'right', append_link: true)
    klass = 'http-selector'
    klass << ' has-tooltip' if current_user.try(:require_extra_setup_for_git_auth?)

    protocol = gitlab_config.protocol.upcase

    tooltip_title =
      if current_user.try(:require_password_creation_for_git?)
        _("Set a password on your account to pull or push via %{protocol}.") % { protocol: protocol }
      else
        _("Create a personal access token on your account to pull or push via %{protocol}.") % { protocol: protocol }
      end

    content_tag (append_link ? :a : :span), protocol,
      class: klass,
      href: (project.http_url_to_repo if append_link),
      data: {
        html: true,
        placement: placement,
        container: 'body',
        title: tooltip_title
      }
  end

  def ssh_clone_button(project, placement = 'right', append_link: true)
    klass = 'ssh-selector'
    klass << ' has-tooltip' if current_user.try(:require_ssh_key?)

    content_tag (append_link ? :a : :span), 'SSH',
      class: klass,
      href: (project.ssh_url_to_repo if append_link),
      data: {
        html: true,
        placement: placement,
        container: 'body',
        title: _('Add an SSH key to your profile to pull or push via SSH.')
      }
  end
end
