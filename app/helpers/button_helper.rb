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

    data = { toggle: 'tooltip', placement: 'bottom', container: 'body' }.merge(data)

    content_tag :button,
      icon('clipboard', 'aria-hidden': 'true'),
      class: "btn #{css_class}",
      data: data,
      type: :button,
      title: title,
      aria: {
        label: title
      }
  end

  def http_clone_button(project, placement = 'right', append_link: true)
    klass = 'http-selector'
    klass << ' has-tooltip' if current_user.try(:require_password_creation?) || current_user.try(:require_personal_access_token_creation_for_git_auth?)

    protocol = gitlab_config.protocol.upcase

    tooltip_title =
      if current_user.try(:require_password_creation?)
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
        title: tooltip_title,
        primary_url: (geo_primary_http_url_to_repo(project) if Gitlab::Geo.secondary?)
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
        title: _('Add an SSH key to your profile to pull or push via SSH.'),
        primary_url: (geo_primary_ssh_url_to_repo(project) if Gitlab::Geo.secondary?)
      }
  end

  def kerberos_clone_button(project)
    klass = 'kerberos-selector'
    klass << ' has-tooltip'

    content_tag :a, 'KRB5',
      class: klass,
      href: project.kerberos_url_to_repo,
      data: {
        html: 'true',
        placement: 'right',
        container: 'body',
        title: 'Get a Kerberos token for your<br>account with kinit.'
      }
  end

  def geo_button(modal_target: nil)
    data = { placement: 'bottom', container: 'body', toggle: 'modal', target: modal_target }
    content_tag :button,
                icon('globe'),
                class: 'btn btn-geo has-tooltip',
                data: data,
                type: :button,
                title: 'See Geo-specific instructions'
  end
end
