# frozen_string_literal: true

module Members
  module Projects
    class CreatorService < Members::CreatorService
      include Gitlab::Utils::StrongMemoize

      private

      def can_create_new_member?
        return false unless service_account_eligible_for_membership?

        # This access check(`admin_project_member`) will write to safe request store cache for the user being added.
        # This means any operations inside the same request will need to purge that safe request
        # store cache if operations are needed to be done inside the same request that checks max member access again on
        # that user.
        current_user.can?(:admin_project_member, member.project) || adding_the_creator_as_owner_in_a_personal_project?
      end

      def service_account_eligible_for_membership?
        return true unless member.user&.service_account?

        ::Members::ServiceAccounts::EligibilityChecker.new(target_project: member.project).eligible?(member.user)
      end
      strong_memoize_attr :service_account_eligible_for_membership?

      def can_update_existing_member?
        current_user.can?(:update_project_member, member)
      end

      # Overrides Members::CreatorService#same_org? to allow the personal namespace
      # holder to be added to their own project even without an organization_users record.
      def same_org?
        return true if adding_the_creator_as_owner_in_a_personal_project?

        super
      end

      # This condition is checked in both can_create_new_member? and same_org?,
      # so memoize to avoid repeated evaluation.
      # This condition is reached during testing setup a lot due to use of `.add_member`
      def adding_the_creator_as_owner_in_a_personal_project?
        member.project.personal_namespace_holder?(member.user)
      end
      strong_memoize_attr :adding_the_creator_as_owner_in_a_personal_project?
    end
  end
end

Members::Projects::CreatorService.prepend_mod_with('Members::Projects::CreatorService')
