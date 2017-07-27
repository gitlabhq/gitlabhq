module EE
  module GroupPolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :subject
      condition(:ldap_synced) { @subject.ldap_synced? }

      rule { reporter }.policy do
        enable :admin_list
        enable :admin_board
      end

      rule { public_group }      .enable :read_board
      rule { guest }             .enable :read_board

      rule { ldap_synced }.prevent :admin_group_member

      rule { ldap_synced & admin }.policy do
        enable :override_group_member
        enable :update_group_member
      end

      rule { ldap_synced & owner }.policy do
        enable :override_group_member
        enable :update_group_member
      end

      rule { auditor }.enable :read_group
    end
  end
end
