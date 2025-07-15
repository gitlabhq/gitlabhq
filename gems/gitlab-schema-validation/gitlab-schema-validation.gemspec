# frozen_string_literal: true

require_relative "lib/gitlab/schema/validation/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-schema-validation"
  spec.version = Gitlab::Schema::Validation::Version::VERSION
  spec.authors = ["group::database"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Schema validation framework"
  spec.description = "Compares the differences between a structure.sql file and a database
    and reports the inconsistencies."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-schema-validation"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_dependency "diffy"
  spec.add_dependency "pg_query"

  spec.add_development_dependency "gitlab-styles", "~> 13.1.0"
  spec.add_development_dependency "pg", "~> 1.5.9"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rspec-benchmark", "~> 0.6.0"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
  spec.add_development_dependency "rubocop", "~> 1.71"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
end
