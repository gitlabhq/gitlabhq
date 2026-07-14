# frozen_string_literal: true

require_relative "lib/gitlab/email_handler/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-email_handler"
  spec.version = Gitlab::EmailHandler::Version::VERSION
  spec.authors = ["group::project management"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Incoming email identification for GitLab"
  spec.description = "Parses incoming email keys to identify the target handler and the resource " \
    "(project, namespace, or route) that owns the email."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-email_handler"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  # This gem performs pure, dependency-free email identification. Resolving a
  # target to a cell and forwarding the email live in the consumer (the
  # mail_room service), so no runtime dependencies are declared here.

  spec.add_development_dependency "gitlab-styles", "~> 14.0"
  # Used only in specs, to exercise MailKey against real Mail::Message objects.
  spec.add_development_dependency "mail", "~> 2.8"
  spec.add_development_dependency "rspec", "~> 3.0"
end
