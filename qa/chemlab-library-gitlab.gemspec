# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

Gem::Specification.new do |spec|
  spec.name = 'chemlab-library-gitlab'
  spec.version = '0.3.0'
  spec.authors = ['GitLab Quality']
  spec.email = ['quality@gitlab.com']

  spec.required_ruby_version = '>= 2.5' # rubocop:disable Gemspec/RequiredRubyVersion

  spec.summary = 'Chemlab Page Libraries for GitLab'
  spec.homepage = 'https://gitlab.com/'
  spec.license = 'MIT'

  spec.files = `git ls-files -- lib/*`.split("\n")

  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'chemlab', '~> 0.9'
  spec.add_runtime_dependency 'zeitwerk', '~> 2.4'
end
