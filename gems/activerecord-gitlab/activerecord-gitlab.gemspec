# frozen_string_literal: true

require_relative "lib/active_record/gitlab_patches/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-gitlab"
  spec.version = ActiveRecord::GitlabPatches::Version::VERSION
  spec.authors = ["group::tenant-scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab ActiveRecord patches"
  spec.description = "GitLab stores any patches relating to ActiveRecord here"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/activerecord-gitlab"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", ">= 7"

  spec.add_development_dependency "gitlab-styles", "~> 10.1.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.22"
  spec.add_development_dependency "sqlite3", "~> 1.6"
end
