# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = "gitlab-cd-driver-orchestration"
  spec.version     = "0.5.0"
  spec.authors     = ["GitLab Engineers"]
  spec.email       = ["engineering@gitlab.com"]

  spec.summary     = "Orchestration engine for GitLab CD deploy drivers"
  spec.description = "Ships the Starlark main() entrypoint and register() machinery that GitLab CD " \
    "deploy drivers plug into, plus the Ruby that assembles the orchestrator and driver " \
    "fragments into a single AutoFlow deploy program."
  spec.homepage    = "https://gitlab.com/gitlab-org/ci-cd/runner-tools/argo-rollout"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Ships Ruby (lib) plus the vendored Starlark engine and manifest data files.
  spec.files         = Dir["lib/**/*.rb", "scripts/**/*.star", "schemas/**/*.json", "manifest.json", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "gitlab-styles", "~> 14.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
end
