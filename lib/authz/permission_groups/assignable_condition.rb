# frozen_string_literal: true

module Authz
  module PermissionGroups
    # Evaluates `assignable_when` conditions declared on assignable
    # permissions. Not a security control: endpoints must still enforce the
    # same conditions at request time.
    class AssignableCondition
      # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- Conditions mirror endpoint gates on the instance type itself, not a SaaS feature
      EVALUATORS = {
        admin: ->(user) { user.can_access_admin_area? },
        # `gitlab_team_member?` is EE-only, hence the `respond_to?` guard.
        gitlab_team_member: ->(user) { user.respond_to?(:gitlab_team_member?) && user.gitlab_team_member? },
        saas: ->(_user) { ::Gitlab.com? },
        self_managed: ->(_user) { !::Gitlab.com? }
      }.freeze
      # rubocop:enable Gitlab/AvoidGitlabInstanceChecks

      def self.satisfied?(conditions, user)
        return true if conditions.empty?
        return false if user.blank?

        conditions.all? { |condition| EVALUATORS.fetch(condition.to_sym).call(user) }
      end
    end
  end
end
