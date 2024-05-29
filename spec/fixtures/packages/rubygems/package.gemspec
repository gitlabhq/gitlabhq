# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'package'
  s.authors = ['Tanuki Steve', 'Hal 9000']
  s.author = 'Tanuki Steve'
  s.version = '0.0.1'
  s.summary = 'package is the best'
  s.files = ['lib/test_gem.rb']
  s.require_paths = ['lib']

  s.description = 'A test package for GitLab.'
  s.email = 'tanuki@not_real.com'
  s.homepage = 'https://gitlab.com/ruby-co/my-package'
  s.license = 'MIT'

  s.metadata = {
    'bug_tracker_uri' => 'https://gitlab.com/ruby-co/my-package/issues',
    'changelog_uri' => 'https://gitlab.com/ruby-co/my-package/CHANGELOG.md',
    'documentation_uri' => 'https://gitlab.com/ruby-co/my-package/docs',
    'mailing_list_uri' => 'https://gitlab.com/ruby-co/my-package/mailme',
    'source_code_uri' => 'https://gitlab.com/ruby-co/my-package'
  }

  s.bindir = 'bin'
  s.executables = ['rake']
  s.extensions = ['ext/foo.rb']
  s.extra_rdoc_files = ['README.md', 'doc/userguide.md']
  s.platform = Gem::Platform::RUBY
  s.post_install_message = 'Installed, thank you!'
  s.rdoc_options = ['--main', 'README.md']
  s.required_ruby_version = '>= 2.7.0' # rubocop:disable Gemspec/RequiredRubyVersion
  s.required_rubygems_version = '>= 1.8.11'
  s.requirements = 'A high powered server or calculator'

  s.add_dependency 'dependency_1', '~> 1.2.3'
  s.add_dependency 'dependency_2', '3.0.0'
  s.add_dependency 'dependency_3', '>= 1.0.0'
  s.add_dependency 'dependency_4'
end
