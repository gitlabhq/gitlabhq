module ButtonHelper
  def http_clone_button(project)
    klass = 'btn'
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
    klass = 'btn'
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
