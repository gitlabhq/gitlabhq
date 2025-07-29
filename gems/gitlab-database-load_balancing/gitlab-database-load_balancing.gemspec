# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "gitlab-database-load_balancing"
  spec.version = "0.1.0"
  spec.authors = ["group::database"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab specific support for read-only replicas"
  spec.description = "Provides a code on top of existing databases to support read-only replicas."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-safe_request_store"
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_dependency 'gitlab-net-dns', '~> 0.12'
  spec.add_dependency "pg", '~> 1.5.6'
  spec.add_dependency 'rails', '>= 7.1'

  spec.add_development_dependency "gitlab-styles", "~> 13.1.0"
  spec.add_development_dependency "pg", '~> 1.5.6'
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0.1"
  spec.add_development_dependency "rubocop", "~> 1.71.1"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0.4"
end
