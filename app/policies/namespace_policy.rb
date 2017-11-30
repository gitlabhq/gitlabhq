class NamespacePolicy < BasePolicy
  rule { anonymous }.prevent_all

  condition(:personal_project, scope: :subject) { @subject.kind == 'user' }
  condition(:can_create_personal_project, scope: :user) { @user.can_create_project? }
  condition(:owner) { @subject.owner == @user }

  rule { owner | admin }.policy do
    enable :create_projects
    enable :admin_namespace
    enable :read_namespace
  end

  rule { personal_project & ~can_create_personal_project }.prevent :create_projects
end
