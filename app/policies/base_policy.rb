require_dependency 'declarative_policy'

class BasePolicy < DeclarativePolicy::Base
  include Gitlab::CurrentSettings

  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) { @user&.admin? }

  with_options scope: :user, score: 0
  condition(:external_user) { @user.nil? || @user.external? }

  with_options scope: :user, score: 0
  condition(:can_create_group) { @user&.can_create_group }

  desc "The application is restricted from public visibility"
  condition(:restricted_public_level, scope: :global) do
    current_application_settings.restricted_visibility_levels.include?(Gitlab::VisibilityLevel::PUBLIC)
  end

  # EE Extensions
  with_scope :user
  condition(:auditor, score: 0) { @user&.auditor? }

  with_scope :user
  condition(:support_bot, score: 0) { @user&.support_bot? }

  with_scope :global
  condition(:license_block) { License.block_changes? }

  rule { ci_job_user }.prevent_all
end
