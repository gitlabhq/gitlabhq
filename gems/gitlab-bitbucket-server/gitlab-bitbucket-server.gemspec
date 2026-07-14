# frozen_string_literal: true

require_relative "lib/bitbucket_server/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-bitbucket-server"
  spec.version = BitbucketServer::VERSION
  spec.authors = ["GitLab Engineers"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab Bitbucket Server API client"
  spec.description = "REST API client for Bitbucket Server / Data Center used by the GitLab importer."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-bitbucket-server"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7", "< 9"
  spec.add_dependency "addressable", "~> 2.8"
  spec.add_dependency "gitlab-http", "~> 0.1"
  spec.add_dependency "gitlab-utils", "~> 0.1"

  spec.add_development_dependency "gitlab-styles", "~> 13.0.1"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0.2"
  spec.add_development_dependency "webmock", "~> 3.18.1"
end
