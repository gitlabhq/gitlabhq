# frozen_string_literal: true

require_relative 'tooling/gitlab_danger'
require_relative 'tooling/danger/request_helper'

Dir["danger/plugins/*.rb"].sort.each { |f| danger.import_plugin(f) }

return if helper.release_automation?

gitlab_danger = GitlabDanger.new(helper.gitlab_helper)

gitlab_danger.rule_names.each do |file|
  danger.import_dangerfile(path: File.join('danger', file))
end

anything_to_post = status_report.values.any? { |data| data.any? }

if gitlab_danger.ci? && anything_to_post
  markdown("**If needed, you can retry the [`danger-review` job](#{ENV['CI_JOB_URL']}) that generated this comment.**")
end
