# frozen_string_literal: true

require_relative "lib/gitlab/safe_request_store/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-safe_request_store"
  spec.version = Gitlab::SafeRequestStore::Version::VERSION
  spec.authors = ["group::tenant-scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Wrapper for RequestStore"
  spec.description = "Provides a safe interface for RequestStore even when it is not active."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-safe_request_store"
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rack", "~> 2.2.8"
  spec.add_runtime_dependency "request_store"

  spec.add_development_dependency "gitlab-styles", "~> 10.1.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.22"
end
