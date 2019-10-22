# frozen_string_literal: true

# Concern handling functionality around deciding whether to send notification
# for activities on a specified branch or not. Will be included in
# ChatNotificationService and PipelinesEmailService classes.
module NotificationBranchSelection
  extend ActiveSupport::Concern

  BRANCH_CHOICES = [
    [_('All branches'), 'all'],
    [_('Default branch'), 'default'],
    [_('Protected branches'), 'protected'],
    [_('Default branch and protected branches'), 'default_and_protected']
  ].freeze

  def notify_for_branch?(data)
    ref = if data[:ref]
            Gitlab::Git.ref_name(data[:ref])
          else
            data.dig(:object_attributes, :ref)
          end

    is_default_branch = ref == project.default_branch
    is_protected_branch = ProtectedBranch.protected?(project, ref)

    case branches_to_be_notified
    when "all"
      true
    when  "default"
      is_default_branch
    when  "protected"
      is_protected_branch
    when  "default_and_protected"
      is_default_branch || is_protected_branch
    else
      false
    end
  end
end
