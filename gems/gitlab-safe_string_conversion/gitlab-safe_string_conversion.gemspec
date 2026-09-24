# frozen_string_literal: true

require_relative "lib/gitlab/safe_string_conversion/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-safe_string_conversion"
  spec.version = Gitlab::SafeStringConversion::Version::VERSION
  spec.authors = ["GitLab Engineers"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Limits string-to-number conversions to prevent DoS attacks"
  spec.description = "Patches String#to_i/#to_r/#to_c and Kernel#Integer/#Rational/#Complex to raise " \
    "when converting an oversized string, preventing algorithmic-complexity DoS attacks."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-safe_string_conversion"
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "gitlab-styles", "~> 14.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-parameterized"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
end
