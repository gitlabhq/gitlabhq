# frozen_string_literal: true

# This file requires config/initializers/1_settings.rb

if Gitlab.config.gitlab.allowed_hosts.present?
  Rails.application.config.hosts << Gitlab.config.gitlab.host << 'unix'
  Rails.application.config.hosts += Gitlab.config.gitlab.allowed_hosts
end

if Rails.env.development?
  Rails.application.config.hosts += [Gitlab.config.gitlab.host, 'unix', 'host.docker.internal', 'docker.for.mac.localhost']

  if ENV['RAILS_HOSTS']
    additional_hosts = ENV['RAILS_HOSTS'].split(',').select(&:presence)
    Rails.application.config.hosts += additional_hosts
  end
end
