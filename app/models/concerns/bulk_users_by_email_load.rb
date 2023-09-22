# frozen_string_literal: true

module BulkUsersByEmailLoad
  extend ActiveSupport::Concern

  included do
    def users_by_emails(emails)
      Gitlab::SafeRequestLoader.execute(resource_key: user_by_email_resource_key, resource_ids: emails) do |emails|
        # have to consider all emails - even secondary, so use all_emails here
        grouped_users_by_email = User.by_any_email(emails, confirmed: true).preload(:emails).group_by(&:all_emails)

        grouped_users_by_email.each_with_object({}) do |(found_emails, users), h|
          found_emails.each { |e| h[e] = users.first if emails.include?(e) } # don't include all emails for an account, only the ones we want
        end
      end
    end

    private

    def user_by_email_resource_key
      "user_by_email_for_#{User.name.underscore.pluralize}:#{self.class}:#{self.id}"
    end
  end
end
