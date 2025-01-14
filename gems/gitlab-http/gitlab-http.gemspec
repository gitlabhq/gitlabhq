# frozen_string_literal: true

require_relative "lib/gitlab/http_v2/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-http"
  spec.version = Gitlab::HTTP_V2::Version::VERSION
  spec.authors = ["GitLab Engineers"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab HTTP client"
  spec.description = "GitLab HTTP client"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-http"
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir['lib/**/*.rb']
  spec.test_files = Dir['spec/**/*']
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activesupport', '~> 7'
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.2'
  spec.add_runtime_dependency 'httparty', '~> 0.21.0'
  spec.add_runtime_dependency 'ipaddress', '~> 0.8.3'
  spec.add_runtime_dependency "railties", "~> 7"
  # See lib/net_http/connect_patch.rb
  spec.add_runtime_dependency "net-http", "= 0.6.0"

  spec.add_development_dependency 'gitlab-styles', '~> 13.0.1'
  spec.add_development_dependency 'rspec-parameterized', '~> 1.0.2'
  spec.add_development_dependency 'rspec-rails', '~> 6.0.3'
  spec.add_development_dependency 'webmock', '~> 3.18.1'
  spec.add_development_dependency 'webrick', '~> 1.8'
end
