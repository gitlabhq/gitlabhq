# frozen_string_literal: true

module Gitlab
  class GitAccessDesign < GitAccess
    extend ::Gitlab::Utils::Override

    def check(_cmd, _changes)
      check_protocol!
      check_can_create_design!
      check_organization_maintenance!

      success_result
    end

    override :push_ability
    def push_ability
      :create_design
    end

    private

    # The design repository container resolves its organization via the project.
    override :check_organization_maintenance!
    def check_organization_maintenance!
      design_project = container.is_a?(::Project) ? container : container.try(:project)

      enforce_organization_maintenance!(design_project&.organization)
    end

    def check_protocol!
      if protocol != 'web'
        raise ::Gitlab::GitAccess::ForbiddenError, "Designs are only accessible using the web interface"
      end
    end

    def check_can_create_design!
      unless user_can_push?
        raise ::Gitlab::GitAccess::ForbiddenError, "You are not allowed to manage designs of this project"
      end
    end
  end
end

Gitlab::GitAccessDesign.prepend_mod_with('Gitlab::GitAccessDesign')
