# frozen_string_literal: true

default_url_options = {
  host: Gitlab.config.gitlab.host,
  protocol: Gitlab.config.gitlab.protocol,
  script_name: Gitlab.config.gitlab.relative_url_root
}

unless Gitlab.config.gitlab_on_standard_port?
  default_url_options[:port] = Gitlab.config.gitlab.port
end

Rails.application.routes.default_url_options = default_url_options
ActionMailer::Base.asset_host = Settings.gitlab['base_url']
