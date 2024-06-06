# frozen_string_literal: true

module Namespaces
  class UserNamespacePolicy < ::NamespacePolicy
    rule { anonymous }.prevent_all

    condition(:can_create_personal_project, scope: :user) { @user.can_create_project? }
    condition(:bot_user_namespace) { @subject.bot_user_namespace? }
    condition(:owner) { @subject.owner == @user }

    rule { owner | admin }.policy do
      enable :owner_access
      enable :create_projects
      enable :import_projects
      enable :admin_namespace
      enable :admin_runner
      enable :read_namespace
      enable :read_namespace_via_membership
      enable :read_statistics
      enable :create_jira_connect_subscription
      enable :admin_package
      enable :read_billing
      enable :edit_billing
    end

    rule { ~can_create_personal_project }.prevent :create_projects, :import_projects

    rule { bot_user_namespace }.prevent :create_projects, :import_projects

    rule { (owner | admin) & can?(:create_projects) }.enable :transfer_projects
  end
end

Namespaces::UserNamespacePolicy.prepend_mod_with('Namespaces::UserNamespacePolicy')
