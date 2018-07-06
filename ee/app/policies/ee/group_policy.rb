module EE
  module GroupPolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :subject
      condition(:ldap_synced) { @subject.ldap_synced? }
      condition(:epics_available) { @subject.feature_available?(:epics) }
      condition(:contribution_analytics_available) do
        @subject.feature_available?(:contribution_analytics)
      end

      condition(:project_creation_level_enabled) { @subject.feature_available?(:project_creation_level) }

      condition(:create_projects_disabled) do
        @subject.project_creation_level == ::EE::Gitlab::Access::NO_ONE_PROJECT_ACCESS
      end

      condition(:developer_master_access) do
        @subject.project_creation_level == ::EE::Gitlab::Access::DEVELOPER_MASTER_PROJECT_ACCESS
      end

      condition(:can_owners_manage_ldap, scope: :global) do
        ::Gitlab::CurrentSettings.current_application_settings
          .allow_group_owners_to_manage_ldap
      end

      rule { reporter }.policy do
        enable :admin_list
        enable :admin_board
      end

      rule { can?(:read_group) & contribution_analytics_available }
        .enable :read_group_contribution_analytics

      rule { can?(:read_group) & epics_available }.enable :read_epic

      rule { reporter & epics_available }.policy do
        enable :create_epic
        enable :admin_epic
        enable :update_epic
      end

      rule { owner & epics_available }.enable :destroy_epic

      rule { ~can?(:read_cross_project) }.policy do
        prevent :read_group_contribution_analytics
        prevent :read_epic
        prevent :create_epic
        prevent :admin_epic
        prevent :update_epic
      end

      rule { auditor }.enable :read_group

      rule { admin | owner }.enable :admin_group_saml

      rule { admin | (can_owners_manage_ldap & owner) }.enable :admin_ldap_group_links

      rule { ldap_synced }.prevent :admin_group_member

      rule { ldap_synced & (admin | owner) }.enable :update_group_member

      rule { ldap_synced & (admin | (can_owners_manage_ldap & owner)) }.enable :override_group_member

      rule { project_creation_level_enabled & developer & developer_master_access }.enable :create_projects
      rule { project_creation_level_enabled & create_projects_disabled }.prevent :create_projects
    end
  end
end
