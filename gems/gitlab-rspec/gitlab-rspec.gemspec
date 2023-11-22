# frozen_string_literal: true

require_relative "lib/gitlab/rspec/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-rspec"
  spec.version = Gitlab::Rspec::Version::VERSION
  spec.authors = ["group::tenant-scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab RSpec extensions"
  spec.description = "A set of useful helpers to configure RSpec with various stubs and CI configs."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-rspec"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", ">= 6.1", "< 8"
  spec.add_runtime_dependency "activesupport", ">= 6.1", "< 8"
  spec.add_runtime_dependency "rspec", "~> 3.0"

  spec.add_development_dependency "factory_bot_rails", "~> 6.2.0"
  spec.add_development_dependency "gitlab-styles", "~> 10.1.0"
  spec.add_development_dependency "rspec-benchmark", "~> 0.6.0"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0.1"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.22"
end
