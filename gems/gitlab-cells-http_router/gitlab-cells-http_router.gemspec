# frozen_string_literal: true

require_relative "lib/gitlab/cells/http_router/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-cells-http_router"
  spec.version = Gitlab::Cells::HttpRouter::Version::VERSION
  spec.authors = ["group::cells infrastructure"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Ruby-side support for the GitLab Cells HTTP Router"
  spec.description = "Generates the artifacts the Cells HTTP Router consumes from GitLab, which " \
    "is the source of truth for how the router must classify requests. Currently the routing " \
    "snapshot: route templates paired with concrete example URLs that the router replays " \
    "against its own routing table to detect drift."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-cells-http_router"
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.2"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "gitlab-styles"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
end
