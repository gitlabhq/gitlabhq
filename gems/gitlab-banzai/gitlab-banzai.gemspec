# frozen_string_literal: true

require_relative "lib/banzai/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-banzai"
  spec.version = Banzai::VERSION
  spec.authors = ["group::planner intelligence"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab Flavored Markdown rendering pipeline"
  spec.description = "Banzai, the GitLab Flavored Markdown rendering pipeline, extracted from the GitLab " \
    "Rails monolith. Contains no ActiveRecord: everything GitLab-specific arrives through ports on " \
    "Banzai::Configuration. Constants keep their original Banzai:: names and lib/banzai/ paths."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-banzai"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.2"
  spec.add_dependency "gitlab-utils", "~> 0.1"
  spec.add_dependency "html-pipeline", "~> 2.14.3"
  spec.add_dependency "nokogiri", "~> 1.18"
  spec.add_dependency "re2", "~> 2.15"
  spec.add_dependency "sanitize", "~> 7.0"

  spec.add_development_dependency "gitlab-styles", "~> 14.1"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
end
