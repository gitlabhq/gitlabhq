# frozen_string_literal: true

require_relative "lib/gitlab/test_balancing/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-test-balancing"
  spec.version = Gitlab::TestBalancing::VERSION
  spec.authors = ["GitLab Engineers"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Client for the GitLab test balancing API"
  spec.description = "Distributes tests across the nodes of a parallel CI/CD job using the GitLab test balancing API"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-test-balancing"
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.2"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'gitlab-styles', '~> 13.0.1'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'webrick', '~> 1.8'
end
