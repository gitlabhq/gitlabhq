class NamespacePolicy < BasePolicy
  rule { anonymous }.prevent_all

  condition(:owner) { @subject.owner == @user }

  rule { owner | admin }.policy do
    enable :create_projects
    enable :admin_namespace
  end
end
