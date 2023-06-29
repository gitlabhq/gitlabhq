# frozen_string_literal: true

require_relative "lib/active_record/gitlab_patches/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-gitlab"
  spec.version = ActiveRecord::GitlabPatches::Version::VERSION
  spec.authors = ["group::tenant-scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab's ActiveRecord patches"
  spec.description = "GitLab stores any patches relating to ActiveRecord here"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/activerecord-gitlab"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.files = Dir['lib/**/*.rb']
  spec.test_files = Dir['spec/**/*']
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", ">= 6.1.7.3"

  spec.add_development_dependency "gitlab-styles", "~> 10.0.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
