# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "click_house-client"
  spec.version = "0.1.0"
  spec.authors = ["group::optimize"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab's client to interact with ClickHouse"
  spec.description = "This Gem provides a simple way to query ClickHouse databases using the HTTP interface."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/click_house-client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.add_runtime_dependency "activesupport", "< 8"
  spec.add_runtime_dependency "addressable", "~> 2.8"
  spec.add_runtime_dependency 'json', '~> 2.7.2'

  spec.add_development_dependency 'gitlab-styles', '~> 12.0.1'
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
end
