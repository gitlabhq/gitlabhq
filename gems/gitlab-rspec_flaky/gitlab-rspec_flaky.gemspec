# frozen_string_literal: true

require_relative "lib/gitlab/rspec_flaky/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-rspec_flaky"
  spec.version = Gitlab::RspecFlaky::Version::VERSION
  spec.authors = ["Engineering Productivity"]
  spec.email = ["quality@gitlab.com"]

  spec.summary = "GitLab's RSpec Flaky test detector"
  spec.description =
    "This gem provide an RSpec listener that allows to detect flaky examples. See " \
    "https://docs.gitlab.com/ee/development/testing_guide/flaky_tests.html#automatic-retries-and-flaky-tests-detection."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-rspec_flaky"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", ">= 6.1", "< 8"
  spec.add_runtime_dependency "rspec", "~> 3.0"

  spec.add_development_dependency "gitlab-styles", "~> 10.1.0"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.22"
end
