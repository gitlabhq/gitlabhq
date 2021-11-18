# frozen_string_literal: true

require 'gitlab-dangerfiles'

gitlab_dangerfiles = Gitlab::Dangerfiles::Engine.new(self)
gitlab_dangerfiles.import_plugins

return if helper.release_automation?

danger.import_plugin('danger/plugins/*.rb')

gitlab_dangerfiles.import_dangerfiles

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
  markdown("**If needed, you can retry the [`danger-review` job](#{ENV['CI_JOB_URL']}) that generated this comment.**")
end
