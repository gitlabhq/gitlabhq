# frozen_string_literal: true

module Emails
  module Imports
    def github_gists_import_errors_email(user_id, errors)
      @errors = errors
      user = User.find(user_id)

      email_with_layout(
        to: user.notification_email_or_default,
        subject: subject(s_('GithubImporter|GitHub Gists import finished with errors'))
      )
    end

    def bulk_import_csv_user_mapping(user_id, group_id, success_count, failed_count = 0)
      user = User.find(user_id)
      @group = Group.find(group_id)
      @success_count = success_count
      @failed_count = failed_count
      @has_errors = failed_count > 0
      @title = if @has_errors
                 s_('BulkImport|Placeholder reassignments completed with errors')
               else
                 s_('BulkImport|Placeholder reassignments completed successfully')
               end

      email_with_layout(
        to: user.notification_email_or_default,
        subject: subject(@title)
      )
    end
  end
end
