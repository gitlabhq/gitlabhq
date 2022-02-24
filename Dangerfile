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

anything_to_post = status_report.values.any? { |data| data.any? }

return unless helper.ci?

def post_labels
  gitlab.api.update_merge_request(gitlab.mr_json['project_id'],
                                  gitlab.mr_json['iid'],
                                  add_labels: project_helper.labels_to_add.join(','))
rescue Gitlab::Error::Forbidden
  labels = project_helper.labels_to_add.map { |label| %Q(~"#{label}") }
  warn("This Merge Request needs to be labelled with #{labels.join(' ')}. Please request a reviewer or maintainer to add them.")
end

if project_helper.labels_to_add.any?
  post_labels
end

if anything_to_post
  markdown("**If needed, you can retry the [🔁 `danger-review` job](#{ENV['CI_JOB_URL']}) that generated this comment.**")
end
