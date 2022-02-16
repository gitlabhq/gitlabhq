# frozen_string_literal: true

module Backup
  class TerraformState < Backup::Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('terraform_state', Settings.terraform_state.storage_path, excludes: ['tmp'])
    end

    def human_name
      _('terraform states')
    end
  end
end
