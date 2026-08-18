# frozen_string_literal: true

module Gitlab
  module Current
    # Resolves which of the three contexts described in
    # https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/organization/contexts/
    # applies: :organization, :user, or :nil - and the entity that context is bound to.
    #
    # A User whose home Organization is isolated has no existence outside it (see ADR 016), so
    # it always wins Organization context, even over an isolated anchor Organization naming a
    # different Organization. The anchor only decides Organization context once the User's own
    # home Organization doesn't already claim it.
    class DataContext
      def initialize(organization: nil, user: nil)
        @organization = organization
        @user = user
      end

      def type
        return :organization if isolated_organization
        return :user if @user.present?

        :nil
      end

      # The entity `type` is bound to: an Organization, a User, or nil.
      def context
        case type
        when :organization then isolated_organization
        when :user then @user
        end
      end

      private

      def isolated_organization
        return @isolated_organization if defined?(@isolated_organization)

        @isolated_organization = home_organization || anchor_organization
      end

      def home_organization
        return unless @user

        # rubocop:disable Gitlab/AvoidUserOrganization -- DataContext is the canonical, deliberate
        # place to resolve a User's home Organization against isolation, not a scattered call site.
        organization_boundary(@user.organization)
        # rubocop:enable Gitlab/AvoidUserOrganization
      end

      def anchor_organization
        organization_boundary(@organization)
      end

      # Only an isolated Organization is a real boundary - a non-isolated Organization isn't
      # one, whether it's a User's home Organization or an anchor named by the request. Returns
      # nil for a non-boundary so #isolated_organization can fall through to its next candidate
      # instead of treating a non-boundary as if it were one.
      def organization_boundary(organization)
        organization if organization&.isolated?
      end
    end
  end
end
