# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__ || '')

require_relative 'lib/ipynb_diff/version'

Gem::Specification.new do |s|
  s.name        = 'ipynbdiff'
  s.version     = IpynbDiff::Version::VERSION
  s.summary     = 'Human Readable diffs for Jupyter Notebooks'
  s.description = 'Better diff for Jupyter Notebooks by first preprocessing them and removing clutter'
  s.authors     = ['Eduardo Bonet']
  s.email       = 'ebonet@gitlab.com'
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files = Dir['lib/**/*.rb']
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 3.0"
  s.homepage = 'https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/ipynbdiff'
  s.license = 'MIT'

  s.add_runtime_dependency 'diffy', '~> 3.4'
  s.add_runtime_dependency 'oj', '~> 3.13.16'

  s.add_development_dependency 'benchmark-memory', '~>0.2.0'
  s.add_development_dependency 'bundler', '~> 2.2'
  s.add_development_dependency 'gitlab-styles', '~> 10.1.0'
  s.add_development_dependency 'pry', '~> 0.14'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.10'
  s.add_development_dependency 'rspec-parameterized', '~> 1.0'
  s.add_development_dependency 'simplecov', '~> 0.22.0'
end
