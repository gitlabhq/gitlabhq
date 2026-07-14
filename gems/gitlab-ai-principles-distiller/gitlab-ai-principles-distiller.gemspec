# frozen_string_literal: true

require_relative 'lib/gitlab/principles_distiller/version'

Gem::Specification.new do |spec|
  spec.name = 'gitlab-ai-principles-distiller'
  spec.version = Gitlab::PrinciplesDistiller::VERSION
  spec.authors = ['group::ci platform']
  spec.email = ['engineering@gitlab.com']

  spec.summary = 'Distill GitLab development principles from SSOT docs into agent-loadable checklists.'
  spec.description = 'Scheduled-job tool that detects drift in docs.gitlab.com SSOT documentation, ' \
    'triggers Duo Workflow distillations to produce per-domain principle checklists, ' \
    'and opens a follow-up MR with the regenerated content.'
  spec.homepage = 'https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-ai-principles-distiller'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']
  spec.executables = %w[
    gitlab-ai-principles-distiller-sync
    gitlab-ai-principles-distiller-provision-flow
    gitlab-ai-principles-distiller-validate
  ]

  spec.add_dependency 'rainbow'

  spec.add_development_dependency 'gitlab-styles'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop-rspec'
end
