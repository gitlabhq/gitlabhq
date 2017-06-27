require 'declarative_policy'

class BasePolicy < DeclarativePolicy::Base
  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) { @user&.admin? }

  with_options scope: :user, score: 0
  condition(:external_user) { @user.nil? || @user.external? }

  with_options scope: :user, score: 0
  condition(:can_create_group) { @user&.can_create_group }

  # EE Extensions
  with_scope :user
  condition(:auditor, score: 0) { @user&.auditor? }

  with_scope :user
  condition(:support_bot, score: 0) { @user&.support_bot? }

  with_scope :global
  condition(:license_block) { License.block_changes? }
end
