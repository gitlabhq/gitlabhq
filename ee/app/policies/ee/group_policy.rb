module EE
  module GroupPolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :subject
      condition(:ldap_synced) { @subject.ldap_synced? }

      rule { reporter }.policy do
        enable :admin_list
        enable :admin_board
        enable :admin_issue
      end

      condition(:can_owners_manage_ldap, scope: :global) do
        current_application_settings.allow_group_owners_to_manage_ldap
      end

      rule { auditor }.enable :read_group

      rule { admin | (can_owners_manage_ldap & owner) }.enable :admin_ldap_group_links

      rule { ldap_synced }.prevent :admin_group_member

      rule { ldap_synced & (admin | owner) }.enable :update_group_member

      rule { ldap_synced & (admin | (can_owners_manage_ldap & owner)) }.enable :override_group_member
    end
  end
end
