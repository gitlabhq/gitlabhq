# frozen_string_literal: true

require_relative "lib/gitlab/rspec/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-rspec"
  spec.version = Gitlab::Rspec::Version::VERSION
  spec.authors = ["group::tenant-scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab's RSpec extensions"
  spec.description = "A set of useful helpers to configure RSpec with various stubs and CI configs."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-rspec"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.files = Dir['lib/**/*.rb']
  spec.test_files = Dir['spec/**/*']
  spec.require_paths = ["lib"]

  spec.add_dependency "rspec", "~> 3.0"
end
