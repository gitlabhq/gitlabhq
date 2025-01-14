# frozen_string_literal: true

require_relative 'lib/gitlab/housekeeper/version'

Gem::Specification.new do |spec|
  spec.name = "gitlab-housekeeper"
  spec.version = Gitlab::Housekeeper::VERSION
  spec.authors = ["group::tenant-scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Gem summary"
  spec.description = "Housekeeping following https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134487"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-housekeeper"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]
  spec.executables   = ['gitlab-housekeeper']

  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'awesome_print'
  spec.add_runtime_dependency 'httparty'
  spec.add_runtime_dependency 'rubocop'

  spec.add_development_dependency 'gitlab-styles'
  spec.add_development_dependency 'rspec-rails', '~>7.0.0'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'webmock'
end
