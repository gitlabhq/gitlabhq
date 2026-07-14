# frozen_string_literal: true

require_relative "lib/auto_freeze/version"

Gem::Specification.new do |spec|
  spec.name = "auto_freeze"
  spec.version = AutoFreeze::VERSION
  spec.authors = ["Thong Kuah"]
  spec.email = ["tkuah@gitlab.com"]

  spec.summary = "Sets the `frozen_string_literal` compile option for your gems."
  spec.description = "Allows you to select specific gems to be required with `frozen_string_literal` set to true."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/auto_freeze"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb', "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "freezolite", "~> 0.6"

  spec.add_development_dependency "gitlab-styles", "~> 14.0"
  spec.add_development_dependency "pry-byebug", "~> 3.12"
end
