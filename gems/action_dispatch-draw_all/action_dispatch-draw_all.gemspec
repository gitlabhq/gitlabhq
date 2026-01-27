# frozen_string_literal: true

require_relative "lib/action_dispatch/draw_all/version"

Gem::Specification.new do |spec|
  spec.name = "action_dispatch-draw_all"
  spec.version = ActionDispatch::DrawAll::VERSION
  spec.authors = ["group::tenant-scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Rails routing extension for drawing multiple route files"
  spec.description = "Adds a draw_all method to ActionDispatch::Routing::Mapper to load " \
    "multiple route files matching a pattern from config/routes directories."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/action_dispatch-draw_all"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", ">= 7"

  spec.add_development_dependency "gitlab-styles", "~> 13.1.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-rails", "~> 6.0.1"
end
