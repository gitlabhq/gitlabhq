# frozen_string_literal: true

require 'gitlab-dangerfiles'

def ee?
  # Support former project name for `dev` and support local Danger run
  %w[gitlab gitlab-ee].include?(ENV['CI_PROJECT_NAME']) || Dir.exist?(File.expand_path('ee', __dir__))
end

project_name = ee? ? 'gitlab' : 'gitlab-foss'

Gitlab::Dangerfiles.for_project(self, project_name) do |gitlab_dangerfiles|
  gitlab_dangerfiles.import_plugins
  gitlab_dangerfiles.config.ci_only_rules = ProjectHelper::CI_ONLY_RULES
  gitlab_dangerfiles.config.files_to_category = ProjectHelper::CATEGORIES

  gitlab_dangerfiles.config.excluded_required_codeowners_sections_for_roulette.push('Database')
  gitlab_dangerfiles.config.included_optional_codeowners_sections_for_roulette.push('Backend Static Code Analysis')

  gitlab_dangerfiles.import_dangerfiles(except: %w[simple_roulette])
end
