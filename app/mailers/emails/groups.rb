# frozen_string_literal: true

module Emails
  module Groups
    def group_was_exported_email(current_user, group)
      group_email(current_user, group, _('Group was exported'))
    end

    def group_was_not_exported_email(current_user, group, errors)
      group_email(current_user, group, _('Group export error'), errors: errors)
    end

    def group_email(current_user, group, subj, errors: nil)
      @group = group
      @errors = errors
      mail_with_locale(to: current_user.notification_email_for(@group), subject: subject(subj))
    end
  end
end
