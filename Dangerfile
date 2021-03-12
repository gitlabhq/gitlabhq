# frozen_string_literal: true

require 'gitlab-dangerfiles'

Gitlab::Dangerfiles.import_plugins(danger)
danger.import_plugin('danger/plugins/*.rb')

return if helper.release_automation?

project_helper.rule_names.each do |rule|
  danger.import_dangerfile(path: File.join('danger', rule))
end

anything_to_post = status_report.values.any? { |data| data.any? }

if helper.ci? && anything_to_post
  markdown("**If needed, you can retry the [`danger-review` job](#{ENV['CI_JOB_URL']}) that generated this comment.**")
end
