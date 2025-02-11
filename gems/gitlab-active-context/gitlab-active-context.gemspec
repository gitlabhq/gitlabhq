# frozen_string_literal: true

require_relative "lib/active_context/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-active-context"
  spec.version = ActiveContext::VERSION
  spec.authors = ["GitLab"]
  spec.email = ["gitlab_rubygems@gitlab.com"]

  spec.summary = "Abstraction for indexing and searching vectors"
  spec.description = "Abstraction for indexing and searching vectors"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-active-context"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'connection_pool'
  spec.add_dependency 'elasticsearch'
  spec.add_dependency 'opensearch-ruby'
  spec.add_dependency 'pg'
  spec.add_dependency 'zeitwerk'

  spec.add_development_dependency 'aws-sdk-core'
  spec.add_development_dependency 'faraday_middleware-aws-sigv4'
  spec.add_development_dependency 'gitlab-styles'
  spec.add_development_dependency 'redis'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'webmock'

  spec.metadata["rubygems_mfa_required"] = "true"
end
