# frozen_string_literal: true

require_relative "lib/safe_zip/version"

Gem::Specification.new do |spec|
  spec.name          = "safe_zip"
  spec.version       = SafeZip::VERSION
  spec.authors       = ["GitLab Engineers"]
  spec.email         = ["engineering@gitlab.com"]
  spec.summary       = "Safe zip archive extraction"
  spec.description   = "Provides a safe interface to extract specific directories or files within a zip archive, preventing path traversal attacks."
  spec.homepage      = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/safe_zip"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rubyzip", "~> 2.4"

  spec.add_development_dependency "gitlab-styles", "~> 14.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
end
