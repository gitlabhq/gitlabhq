# frozen_string_literal: true

require_relative 'lib/gitlab_danger'
require_relative 'lib/gitlab/danger/request_helper'

danger.import_plugin('danger/plugins/helper.rb')
danger.import_plugin('danger/plugins/roulette.rb')
danger.import_plugin('danger/plugins/changelog.rb')

unless helper.release_automation?
  GitlabDanger.new(helper.gitlab_helper).rule_names.each do |file|
    danger.import_dangerfile(path: File.join('danger', file))
  end
end
