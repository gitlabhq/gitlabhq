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

  spec.add_dependency "activesupport", "~> 7.0.8"
  spec.add_dependency "rainbow", "~> 3.0"
  spec.add_dependency "thor", "~> 1.3"

  spec.add_development_dependency "factory_bot", "~> 6.4.6"
  spec.add_development_dependency "gitlab-styles", "~> 11.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-rails", "<= 2.20" # https://github.com/rubocop/rubocop-rails/issues/1173
end
