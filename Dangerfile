# frozen_string_literal: true
danger.import_plugin('danger/plugins/helper.rb')
danger.import_plugin('danger/plugins/roulette.rb')

unless helper.release_automation?
  danger.import_dangerfile(path: 'danger/metadata')
  danger.import_dangerfile(path: 'danger/changes_size')
  danger.import_dangerfile(path: 'danger/changelog')
  danger.import_dangerfile(path: 'danger/specs')
  danger.import_dangerfile(path: 'danger/gemfile')
  danger.import_dangerfile(path: 'danger/database')
  danger.import_dangerfile(path: 'danger/documentation')
  danger.import_dangerfile(path: 'danger/frozen_string')
  danger.import_dangerfile(path: 'danger/commit_messages')
  danger.import_dangerfile(path: 'danger/duplicate_yarn_dependencies')
  danger.import_dangerfile(path: 'danger/prettier')
  danger.import_dangerfile(path: 'danger/eslint')
  danger.import_dangerfile(path: 'danger/roulette')
  danger.import_dangerfile(path: 'danger/single_codebase')
  danger.import_dangerfile(path: 'danger/gitlab_ui_wg')
  danger.import_dangerfile(path: 'danger/ce_ee_vue_templates')
  danger.import_dangerfile(path: 'danger/only_documentation')
end
