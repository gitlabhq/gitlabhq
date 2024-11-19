# frozen_string_literal: true

module BulkUsersByEmailLoad
  extend ActiveSupport::Concern

  included do
    def users_by_emails(emails)
      Gitlab::SafeRequestLoader.execute(resource_key: user_by_email_resource_key, resource_ids: emails) do |emails|
        # We have to consider all emails - even secondary, so use all_emails here to accomplish that.
        # The by_any_email method will search for lowercased emails only, which means the
        # private_commit_email values may not get cached properly due to it being able to be non-lowercased.
        # That is likely ok as the use of those in the current use of this construct is likely very rare.
        # Perhaps to be looked at more in https://gitlab.com/gitlab-org/gitlab/-/issues/461885
        grouped_users_by_email = User.by_any_email(emails, confirmed: true).preload(:emails).group_by(&:all_emails)

        grouped_users_by_email.each_with_object({}) do |(found_emails, users), h|
          found_emails.each do |e| # don't include all emails for an account, only the ones we want
            h[e] = users.first if emails.include?(e)
          end
        end
      end
    end

    private

    def user_by_email_resource_key
      "user_by_email_for_#{User.name.underscore.pluralize}:#{self.class}:#{self.id}"
    end
  end
end
