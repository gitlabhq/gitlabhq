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
      class: "btn btn-clipboard",
      data: data,
      type: :button
  end

  # Output a "Copy to Clipboard" button with a custom CSS class
  #
  # data - Data attributes passed to `content_tag`
  # css_class - Class passed to the `content_tag`
  #
  # Examples:
  # 
  #   # Define the target element
  #   clipboard_button_with_class({clipboard_target: "div#foo"}, css_class: "btn-clipboard")
  #   # => "<button class='btn btn-clipboard' data-clipboard-target='div#foo'>...</button>"
  def clipboard_button_with_class(data = {}, css_class: 'btn-clipboard')
    content_tag :button,
      icon('clipboard'),
      class: "btn #{css_class}",
      data: data,
      type: :button
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
end
