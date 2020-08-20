# frozen_string_literal: true

class AddDefaultMembershipRoleToSamlProvider < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  GUEST_USER_ROLE = 10

  def change
    add_column :saml_providers, :default_membership_role, :smallint, default: GUEST_USER_ROLE, null: false
  end
end
