# frozen_string_literal: true

module Backup
  class Builds < Backup::Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('builds', Settings.gitlab_ci.builds_path)
    end
  end
end
