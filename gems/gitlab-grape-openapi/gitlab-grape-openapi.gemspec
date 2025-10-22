# frozen_string_literal: true

require_relative "lib/gitlab/grape_openapi/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-grape-openapi"
  spec.version = Gitlab::GrapeOpenapi::VERSION
  spec.authors = ["group::api"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary       = "Generate OpenAPI 3.0 specifications from Grape APIs"
  spec.description   = "A Ruby gem that introspects Grape API definitions and generates OpenAPI 3.0 specification files"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "grape", "~> 2.0.0"
  spec.add_dependency "grape-entity", "~> 1.0.1"

  spec.add_development_dependency "gitlab-styles", "~> 13.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.71"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
end
