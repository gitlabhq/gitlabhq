# frozen_string_literal: true

module Backup
  class Builds < Backup::Files
    def initialize(progress)
      super(progress, 'builds', Settings.gitlab_ci.builds_path)
    end

    override :human_name
    def human_name
      _('builds')
    end
  end
end
