# frozen_string_literal: true

module QA
  module Flow
    module UserOnboarding
      extend self

      def onboard_user
        # Implemented in EE only
      end

      # Complete the self-managed admin first-run onboarding flow if it is shown.
      #
      # On a fresh self-managed instance with no groups, an administrator's first UI
      # sign-in is redirected to /admin/registrations/groups/new (see
      # app/controllers/sessions_controller.rb#should_redirect_to_sm_onboarding?), then
      # to /admin/registrations/profile. Both steps render without the super sidebar, so
      # Page::Main::Menu validation fails unless we move past them first.
      #
      # We create a group (rather than skip) on the first step: that clears the
      # instance-wide `Group.exists?` check the redirect is gated on, so onboarding does
      # not recur on subsequent admin sign-ins. The profile step is then completed to
      # land the admin on the dashboard.
      #
      # No-op on instances that already have a group (the pages never appear).
      #
      # @return [void]
      def complete_admin_onboarding
        on_onboarding = false

        Page::Admin::Registrations::Group.perform do |group_step|
          next unless group_step.shown?(wait: 0)

          on_onboarding = true
          group_step.create_initial_group
        end

        return unless on_onboarding

        Page::Admin::Registrations::Profile.perform do |profile_step|
          profile_step.complete if profile_step.shown?(wait: 2)
        end

        nil
      end

      def create_initial_project
        # Implemented in EE only
      end
    end
  end
end

QA::Flow::UserOnboarding.prepend_mod_with('Flow::UserOnboarding', namespace: QA)
