# frozen_string_literal: true

require_relative "lib/gitlab/database/data_isolation/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-database-data_isolation"
  spec.version = Gitlab::Database::DataIsolation::VERSION
  spec.authors = ["group::tenant-scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Database row-level data isolation for ActiveRecord"
  spec.description = "Provides row-level data isolation via sharding key filtering"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-database-data_isolation"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7"

  spec.add_development_dependency "gitlab-styles", "~> 13.1.0"
  spec.add_development_dependency "pg", "~> 1.5"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
  spec.add_development_dependency "rubocop", "~> 1.71"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0.4"
end
