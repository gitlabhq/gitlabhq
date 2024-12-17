# frozen_string_literal: true

module Admin
  module UsersHelper
    def show_admin_new_user_organization_field?
      Feature.enabled?(:ui_for_organizations, current_user) && ::Organizations::Organization.exists?
    end

    def show_admin_edit_user_organization_field?(user)
      Feature.enabled?(:ui_for_organizations, current_user) && user.organizations.exists?
    end

    def admin_new_user_organization_field_app_data
      initial_organization = ::Organizations::Organization.first

      {
        has_multiple_organizations: ::Organizations::Organization.limit(2).count > 1
      }.merge(admin_user_organization_field_shared(initial_organization)).to_json
    end

    def admin_edit_user_organization_field_app_data(user)
      initial_organization = user.organizations.first
      organization_user = initial_organization.organization_users.by_user(user).first

      {
        organization_user: organization_user.slice(:id, :access_level)
      }.merge(admin_user_organization_field_shared(initial_organization)).to_json
    end

    private

    def admin_user_organization_field_shared(initial_organization)
      {
        initial_organization: initial_organization.slice(
          :id,
          :name
        ).merge({ avatar_url: initial_organization.avatar_url(size: 96) })
      }
    end
  end
end
