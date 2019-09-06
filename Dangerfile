# frozen_string_literal: true

require_relative 'lib/gitlab_danger'

danger.import_plugin('danger/plugins/helper.rb')
danger.import_plugin('danger/plugins/roulette.rb')

unless helper.release_automation?
  GitlabDanger.new(helper.gitlab_helper).rule_names.each do |file|
    danger.import_dangerfile(path: File.join('danger', file))
  end
end
