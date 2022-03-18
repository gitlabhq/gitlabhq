# frozen_string_literal: true

module Backup
  class Registry < Backup::Files
    def initialize(progress)
      super(progress, 'registry', Settings.registry.path)
    end

    override :human_name
    def human_name
      _('container registry images')
    end

    override :enabled
    def enabled
      Gitlab.config.registry.enabled
    end
  end
end
