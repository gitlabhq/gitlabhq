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

if project_helper.labels_to_add.any?
  gitlab.api.update_merge_request(gitlab.mr_json['project_id'],
                                  gitlab.mr_json['iid'],
                                  add_labels: project_helper.labels_to_add.join(','))
end

if anything_to_post
  markdown("**If needed, you can retry the [`danger-review` job](#{ENV['CI_JOB_URL']}) that generated this comment.**")
end
