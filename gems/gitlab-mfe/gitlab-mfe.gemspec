# frozen_string_literal: true

require_relative "lib/gitlab/mfe/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-mfe"
  spec.version = Gitlab::Mfe::VERSION
  spec.authors = ["group::compliance"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab micro-frontend (MFE) delivery configuration and vendor pins"
  spec.description = "Reads the committed MFE version pin file and exposes the delivery gate and registry URL."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-mfe"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7", "< 9"
  spec.add_dependency "gitlab-utils", "~> 0.1"

  spec.add_development_dependency "gitlab-styles", "~> 14.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
end
