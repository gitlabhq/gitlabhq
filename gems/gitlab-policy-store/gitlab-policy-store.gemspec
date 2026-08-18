# frozen_string_literal: true

require_relative "lib/gitlab/policy_store/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-policy-store"
  spec.version = Gitlab::PolicyStore::Version::VERSION
  spec.authors = ["group::security policies"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Storage-agnostic management layer for GitLab security policies"
  spec.description = "Public facade, ports, and adapters for storing and reading " \
    "governance policies, decoupled from any specific persistence backend so the " \
    "in-monolith storage can later be swapped for a remote service."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-policy-store"
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "gitlab-styles"
  spec.add_development_dependency "rspec", "~> 3.12"
end
