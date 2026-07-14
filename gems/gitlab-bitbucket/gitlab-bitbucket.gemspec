# frozen_string_literal: true

require_relative 'lib/bitbucket/version'

Gem::Specification.new do |spec|
  spec.name = "gitlab-bitbucket"
  spec.version = Bitbucket::VERSION
  spec.authors = ["GitLab Engineers"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab Bitbucket Cloud API client"
  spec.description = "REST API client for Bitbucket Cloud, used by the GitLab Bitbucket Cloud importer."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-bitbucket"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7", "< 9"
  # Required only because Bitbucket::ExponentialBackoff rescues HTTParty::ResponseError to
  # classify retryable HTTP statuses. The HTTP client itself is injected, so this coupling to
  # the concrete library should be removed eventually:
  # https://gitlab.com/gitlab-org/gitlab/-/work_items/604233
  spec.add_dependency "httparty", "~> 0.24"
  spec.add_dependency "oauth2", "~> 2.0"
  spec.add_dependency "omniauth-oauth2", "~> 1.8"
  spec.add_dependency "rack", ">= 2.2"

  spec.add_development_dependency "gitlab-styles", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
  spec.add_development_dependency "webmock", "~> 3.18"
end
