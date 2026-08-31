# frozen_string_literal: true

module Emails
  module Organizations
    def organization_activated_email(organization_id, user_id)
      @organization = ::Organizations::Organization.find_by_id(organization_id)
      @user = User.find_by_id(user_id)
      return unless @organization && @user

      @target_url = @organization.web_url

      email_with_layout(
        to: @user.notification_email_or_default,
        subject: subject(
          format(
            s_('Notify|Your organization %{organization_name} is ready'),
            organization_name: @organization.name
          )
        )
      )
    end
  end
end
