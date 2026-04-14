# frozen_string_literal: true

require_relative "lib/gitlab/glaz/version"

Gem::Specification.new do |spec|
  spec.name          = "gitlab-glaz"
  spec.version       = Gitlab::Glaz::VERSION
  spec.authors       = ["group::authorization"]
  spec.email         = ["engineering@gitlab.com"]
  spec.summary       = "Ruby client for the Glaz authorization engine"
  spec.description   = "Wraps the Rust-backed Glaz CheckEngine exposed via magnus FFI"
  spec.homepage      = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-glaz"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"
end
