# frozen_string_literal: true

require_relative "lib/gitlab/utils/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-utils"
  spec.version = Gitlab::Utils::Version::VERSION
  spec.authors = ["group::tenant scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab common helper methods"
  spec.description = "A set of useful helpers methods to perform various conversions and checks."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-utils"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "actionview", ">= 6.1.7.2"
  spec.add_runtime_dependency "activesupport", ">= 6.1.7.2"
  spec.add_runtime_dependency "addressable", "~> 2.8"
  spec.add_runtime_dependency "rake", "~> 13.0"

  spec.add_development_dependency "factory_bot_rails", "~> 6.2.0"
  spec.add_development_dependency "gitlab-styles", "~> 10.1.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-benchmark", "~> 0.6.0"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0.1"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.22"
end
