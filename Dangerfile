# frozen_string_literal: true

require 'gitlab-dangerfiles'

def ee?
  # Support former project name for `dev` and support local Danger run
  %w[gitlab gitlab-ee].include?(ENV['CI_PROJECT_NAME']) || Dir.exist?(File.expand_path('ee', __dir__))
end

project_name = ee? ? 'gitlab' : 'gitlab-foss'

Gitlab::Dangerfiles.for_project(self, project_name) do |gitlab_dangerfiles|
  gitlab_dangerfiles.import_plugins

  unless helper.release_automation?
    danger.import_plugin('danger/plugins/*.rb')
    gitlab_dangerfiles.import_dangerfiles(except: %w[simple_roulette])
    gitlab_dangerfiles.config.files_to_category = ProjectHelper::CATEGORIES
  end
end

return if helper.release_automation?

project_helper.rule_names.each do |rule|
  danger.import_dangerfile(path: File.join('danger', rule))
end
