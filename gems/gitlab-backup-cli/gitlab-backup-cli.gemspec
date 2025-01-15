# frozen_string_literal: true

require_relative "lib/gitlab/backup/cli/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-backup-cli"
  spec.version = Gitlab::Backup::Cli::VERSION
  spec.authors = ["Gabriel Mazetto"]
  spec.email = ["brodock@gmail.com"]

  spec.summary = "GitLab Backup CLI"
  spec.description = "GitLab Backup CLI"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-backup-cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir['lib/**/*.rb']

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7"
  spec.add_dependency "activesupport", ">= 7"
  spec.add_dependency "googleauth", "~> 1.8.1" # https://gitlab.com/gitlab-org/gitlab/-/issues/449019
  spec.add_dependency "google-cloud-storage_transfer", "~> 1.2.0"
  spec.add_dependency "pg", "~> 1.5.6"
  spec.add_dependency "rainbow", "~> 3.0"
  spec.add_dependency "thor", "~> 1.3"

  # The following gems are pinned at specific version to keep
  # gem versions at par with gitlab/Gemfile
  spec.add_dependency "addressable", "~> 2.8"
  spec.add_dependency "concurrent-ruby", "~> 1.1"
  spec.add_dependency "faraday", "~> 2"
  spec.add_dependency "google-protobuf", "~> 3.25", ">= 3.25.3"
  spec.add_dependency "grpc", "= 1.63.0"
  spec.add_dependency "json", "~> 2.7.2"
  spec.add_dependency "jwt", "~> 2.5"
  spec.add_dependency "logger", "~> 1.5.3"
  spec.add_dependency "minitest", "~> 5.11.0"
  spec.add_dependency "parallel", "~> 1.19"
  spec.add_dependency "rack", "~> 2.2.9"
  spec.add_dependency "rexml", "~> 3.4.0"

  spec.add_development_dependency "factory_bot", "~> 6.4.6"
  spec.add_development_dependency "gitlab-styles", "~> 11.0"
  spec.add_development_dependency "parser", "= 3.3.3.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-factory_bot", "~> 2.25.1" # https://github.com/rubocop/rubocop-rspec/issues/1916
  spec.add_development_dependency "rubocop-rspec", "~> 2.27.1"
end
