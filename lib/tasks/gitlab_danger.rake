# frozen_string_literal: true

desc 'Run local Danger rules'
task :danger_local do
  require_relative '../../tooling/danger/project_helper'
  require 'gitlab/popen'

  puts("#{Tooling::Danger::ProjectHelper.local_warning_message}\n")

  # _status will _always_ be 0, regardless of failure or success :(
  output, _status = Gitlab::Popen.popen(%w{danger dry_run})

  if output.empty?
    puts(Tooling::Danger::ProjectHelper.success_message)
  else
    puts(output)
    exit(1)
  end
end
