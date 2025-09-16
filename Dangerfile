# frozen_string_literal: true

require 'gitlab-dangerfiles'

# Version check for gitlab-dangerfiles gem to prevent cryptic error messages
begin
  gem_version = Gem::Specification.find_by_name('gitlab-dangerfiles').version

  unless Gem::Requirement.new('>= 4.0.0').satisfied_by?(gem_version)
    message "\n❌ ERROR: Incompatible gitlab-dangerfiles version detected!"
    message "Found version: #{gem_version}"
    message 'Required version: >= 4.0.0 (preferably ~> 4.9.0)'
    message "\n🔧 To fix this issue:"
    message '1. Run: bundle install'
    message '2. Or run: gem update gitlab-dangerfiles'
    message '3. Or clear gem cache: gem cleanup gitlab-dangerfiles'
    message "\n💡 This prevents the cryptic 'doesn't contain valid danger plugins' error."
    message '   when old gitlab-dangerfiles versions are cached.'
    exit 1
  end
rescue StandardError => e
  message "\n⚠️  Warning: Could not verify gitlab-dangerfiles version: #{e.message}"
  message 'Proceeding anyway, but if you see "doesn\'t contain valid danger plugins",'
  message 'try: bundle install or gem update gitlab-dangerfiles'
end

def ee?
  # Support former project name for `dev` and support local Danger run
  %w[gitlab gitlab-ee].include?(ENV['CI_PROJECT_NAME']) ||
    Dir.exist?(File.expand_path('ee', __dir__))
end

project_name = ee? ? 'gitlab' : 'gitlab-foss'

Gitlab::Dangerfiles.for_project(self, project_name) do |gitlab_dangerfiles|
  gitlab_dangerfiles.import_plugins
  gitlab_dangerfiles.config.ci_only_rules = ProjectHelper::CI_ONLY_RULES
  gitlab_dangerfiles.config.files_to_category = ProjectHelper::CATEGORIES
  gitlab_dangerfiles.config.excluded_required_codeowners_sections_for_roulette.push('Database')
  gitlab_dangerfiles.config.included_optional_codeowners_sections_for_roulette.push(
    'Backend Static Code Analysis'
  )
  gitlab_dangerfiles.import_dangerfiles(except: %w[simple_roulette])
end
