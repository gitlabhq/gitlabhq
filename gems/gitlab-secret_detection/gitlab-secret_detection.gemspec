# frozen_string_literal: true

require_relative "lib/gitlab/secret_detection/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-secret_detection"
  spec.version = Gitlab::SecretDetection::VERSION
  spec.authors = ["group::secret detection"]
  spec.email = ["eng-dev-secure-secret-detection@gitlab.com"]

  spec.summary = "The gitlab-secret_detection gem performs regex matching on git blobs that may include secrets."
  spec.description = "The gitlab-secret_detection gem accepts one or more git blobs,
   matches them against a defined ruleset of regular expressions (based on gitleaks.toml used by secrets analyzer),
   and returns scan results."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-secret_detection"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-secret_detection/CHANGELOG.md"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "grpc", "= 1.63.0"
  spec.add_runtime_dependency "grpc-tools", "= 1.63.0"
  spec.add_runtime_dependency "parallel", "~> 1.22"
  spec.add_runtime_dependency "re2", "~> 2.7"
  spec.add_runtime_dependency "toml-rb", "~> 2.2"

  spec.add_development_dependency "benchmark-malloc", "~> 0.2"
  spec.add_development_dependency "gitlab-styles", "~> 11.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-benchmark", "~> 0.6.0"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0"
  spec.add_development_dependency "rubocop", "~> 1.57"
  spec.add_development_dependency "rubocop-rails", "<= 2.20" # https://github.com/rubocop/rubocop-rails/issues/1173
  spec.add_development_dependency "rubocop-rspec", "~> 2.22"
end
