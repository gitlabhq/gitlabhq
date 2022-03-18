# frozen_string_literal: true

module Backup
  class TerraformState < Backup::Files
    def initialize(progress)
      super(progress, 'terraform_state', Settings.terraform_state.storage_path, excludes: ['tmp'])
    end

    override :human_name
    def human_name
      _('terraform states')
    end
  end
end
