# frozen_string_literal: true

module Organizations
  class OrganizationPolicy < BasePolicy
    condition(:organization_user) { @subject.user?(@user) }
    desc "User owns the organization"
    condition(:organization_owner) { owns_organization? }

    desc 'Organization is public'
    condition(:public_organization, scope: :subject, score: 0) { @subject.public? }

    rule { public_organization }.policy do
      enable :read_organization
    end

    rule { admin }.policy do
      enable :admin_organization
      enable :create_group
      enable :read_organization
      enable :read_organization_user
    end

    rule { organization_owner }.policy do
      enable :admin_organization
      enable :read_organization_user
    end

    rule { organization_user }.policy do
      enable :read_organization
      enable :create_group
    end

    # rubocop:disable Cop/UserAdmin -- specifically check the admin attribute
    def owns_organization?
      return false unless user_is_user?
      # Ensure admins can't bypass admin mode.
      return false if @user.admin? && !can?(:admin)

      # Load the owners with a single query.
      @subject.owner_user_ids.include?(@user.id)
    end
    # rubocop:enable Cop/UserAdmin
  end
end

Organizations::OrganizationPolicy.prepend_mod_with('Organizations::OrganizationPolicy')
