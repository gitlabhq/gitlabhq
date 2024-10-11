# frozen_string_literal: true

module Organizations
  class OrganizationUserPolicy < BasePolicy
    delegate :organization

    condition(:last_owner) { @subject.last_owner? }

    # TODO - https://gitlab.com/gitlab-org/gitlab/-/issues/461792
    # In Cells 1.0, the user will belong to a single organization so the organization owns that user.
    # This will change in Cells 1.5 then users can belong to multiple organizations so the organizations would not
    # necessarily own the user. Then we would have to update this rule.
    rule { can?(:admin_organization) & ~last_owner }.policy do
      enable :update_organization_user
      enable :remove_user
      enable :delete_user
    end
  end
end
