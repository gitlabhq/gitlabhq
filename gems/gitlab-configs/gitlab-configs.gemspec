# frozen_string_literal: true

require_relative "lib/gitlab/configs/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-configs"
  spec.version = Gitlab::Configs::VERSION
  spec.authors = ["GitLab Engineers"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab settings and configuration loading"
  spec.description = "Provides GitLab YAML-based settings loading with lazy evaluation and safe options access."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-configs"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7", "< 9"

  spec.add_development_dependency "gitlab-styles"
  spec.add_development_dependency "rspec", "~> 3.12"
end
