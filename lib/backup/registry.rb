# frozen_string_literal: true

module Backup
  class Registry < Backup::Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('registry', Settings.registry.path)
    end

    def human_name
      _('container registry images')
    end

    def enabled
      Gitlab.config.registry.enabled
    end
  end
end
