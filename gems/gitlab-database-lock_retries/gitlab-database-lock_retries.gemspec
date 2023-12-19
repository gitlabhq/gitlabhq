# frozen_string_literal: true

require_relative "lib/gitlab/database/lock_retries/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-database-lock_retries"
  spec.version = Gitlab::Database::LockRetries::VERSION
  spec.authors = ["group::database"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Gem summary"
  spec.description = "A more descriptive text about what the gem is doing."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-database-lock_retries"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "gitlab-styles", "~> 10.1.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
