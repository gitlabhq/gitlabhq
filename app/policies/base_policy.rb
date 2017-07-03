require_dependency 'declarative_policy'

class BasePolicy < DeclarativePolicy::Base
  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) { @user&.admin? }

  with_options scope: :user, score: 0
  condition(:external_user) { @user.nil? || @user.external? }

  with_options scope: :user, score: 0
  condition(:can_create_group) { @user&.can_create_group }
end
