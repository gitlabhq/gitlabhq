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
  # There is a bug in require-hooks 0.3.0 https://github.com/ruby-next/freezolite/issues/5
  spec.add_dependency "require-hooks", "~> 0.2.3"

  spec.add_development_dependency "gitlab-styles", "~> 14.0"
  spec.add_development_dependency "pry-byebug", "~> 3.12"
  spec.add_development_dependency "pry-shell", "~> 0.6.4"
  spec.add_development_dependency "unicode_utils", "1.4.0"
end
