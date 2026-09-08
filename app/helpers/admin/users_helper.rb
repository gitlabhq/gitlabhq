# frozen_string_literal: true

module Admin
  module UsersHelper
    def show_admin_new_user_organization_field?
      ui_for_organizations_enabled? && ::Organizations::Organization.exists?
    end

    def show_admin_edit_user_organization_field?(user)
      ui_for_organizations_enabled? && user.organizations.exists?
    end

    def admin_new_user_organization_field_app_data
      initial_organization = ::Organizations::Organization.first

      {
        has_multiple_organizations: ::Organizations::Organization.limit(2).count > 1
      }.merge(admin_user_organization_field_shared(initial_organization)).to_json
    end

    def admin_edit_user_organization_field_app_data(user)
      initial_organization = user.organization
      organization_user = initial_organization.organization_users.by_user(user).first

      {
        organization_user: organization_user.slice(:id, :access_level)
      }.merge(admin_user_organization_field_shared(initial_organization)).to_json
    end

    def email_otp_status_text(user)
      return %{Yes (#{user.email_otp_required_after.to_fs(:medium)})} if user.email_otp_required_after

      'No'
    end

    def invite_organization_user_app_data(organization, has_new_user_button:)
      # Demote to the default variant when the "New user" confirm button shares
      # the page header, to keep a single primary action per Pajamas guidance.
      button_variant = has_new_user_button ? 'default' : 'confirm'

      {
        organization_gid: organization.to_global_id,
        organization_name: organization.name,
        search_url: autocomplete_users_path(format: :json),
        button_variant: button_variant
      }.to_json
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
