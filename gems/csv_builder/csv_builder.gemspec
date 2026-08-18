# frozen_string_literal: true

require_relative "lib/csv_builder/version"

Gem::Specification.new do |spec|
  spec.name = "csv_builder"
  spec.version = CsvBuilder::Version::VERSION
  spec.authors = ["group::tenant-scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Provides enhancements to the CSV standard library"
  spec.description = "Provides enhancements to the CSV standard library"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/csv_builder"
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.0.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_dependency "csv"

  # base64, bigdecimal and mutex_m are former default gems that ActiveSupport
  # 7.0 (pulled in by the gitlab-styles RuboCop toolchain) requires without
  # declaring. Ruby 3.4 no longer ships them, so RuboCop's config load fails
  # unless they are present.
  spec.add_development_dependency "base64"
  spec.add_development_dependency "bigdecimal"
  spec.add_development_dependency "gitlab-styles", "~> 14.0"
  spec.add_development_dependency "mutex_m"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
end
