module ButtonHelper
  # Output a "Copy to Clipboard" button
  #
  # data - Data attributes passed to `content_tag`
  #
  # Examples:
  #
  #   # Define the clipboard's text
  #   clipboard_button(clipboard_text: "Foo")
  #   # => "<button class='...' data-clipboard-text='Foo'>...</button>"
  #
  #   # Define the target element
  #   clipboard_button(clipboard_target: "div#foo")
  #   # => "<button class='...' data-clipboard-target='div#foo'>...</button>"
  #
  # See http://clipboardjs.com/#usage
  def clipboard_button(data = {})
    data = { toggle: 'tooltip', placement: 'bottom', container: 'body' }.merge(data)
    content_tag :button,
      icon('clipboard'),
      class: "btn btn-clipboard",
      data: data,
      type: :button,
      title: "Copy to Clipboard"
  end

  def http_clone_button(project, placement = 'right', append_link: true)
    klass = 'http-selector'
    klass << ' has-tooltip' if current_user.try(:require_password?)

    protocol = gitlab_config.protocol.upcase

    content_tag (append_link ? :a : :span), protocol,
      class: klass,
      href: (project.http_url_to_repo if append_link),
      data: {
        html: true,
        placement: placement,
        container: 'body',
        title: "Set a password on your account<br>to pull or push via #{protocol}"
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
        title: 'Add an SSH key to your profile<br>to pull or push via SSH.'
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
end
