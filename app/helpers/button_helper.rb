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
    content_tag :button,
      icon('clipboard'),
      class: 'btn btn-clipboard',
      data: data,
      type: :button
  end

  def http_clone_button(project)
    klass = 'btn js-protocol-switch'
    klass << ' active'      if default_clone_protocol == 'http'
    klass << ' has_tooltip' if current_user.try(:require_password?)

    protocol = gitlab_config.protocol.upcase

    content_tag :button, protocol,
      class: klass,
      data: {
        clone: project.http_url_to_repo,
        container: 'body',
        html: 'true',
        title: "Set a password on your account<br>to pull or push via #{protocol}"
      },
      type: :button
  end

  def ssh_clone_button(project)
    klass = 'btn js-protocol-switch'
    klass << ' active'      if default_clone_protocol == 'ssh'
    klass << ' has_tooltip' if current_user.try(:require_ssh_key?)

    content_tag :button, 'SSH',
      class: klass,
      data: {
        clone: project.ssh_url_to_repo,
        container: 'body',
        html: 'true',
        title: 'Add an SSH key to your profile<br>to pull or push via SSH.'
      },
      type: :button
  end
end
