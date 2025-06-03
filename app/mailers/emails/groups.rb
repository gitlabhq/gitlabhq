# frozen_string_literal: true

module Emails
  module Groups
    include Namespaces::DeletableHelper

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

    def group_scheduled_for_deletion(recipient_id, group_id)
      @group = ::Group.find(group_id)
      @user = ::User.find(recipient_id)
      @deletion_due_in_days = ::Gitlab::CurrentSettings.deletion_adjourned_period.days
      @deletion_date = permanent_deletion_date_formatted(@group, format: '%B %-d, %Y')

      email_with_layout(
        to: @user.email,
        subject: subject('Group scheduled for deletion')
      )
    end
  end
end

Emails::Groups.prepend_mod
