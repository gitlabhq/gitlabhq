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

    def bulk_import_complete(user_id, bulk_import_id)
      user = User.find(user_id)
      @bulk_import = BulkImport.find(bulk_import_id)
      @hostname = @bulk_import.configuration.url
      title = safe_format(
        s_('BulkImport|Import from %{hostname} completed'),
        hostname: @hostname
      )

      email_with_layout(
        to: user.notification_email_or_default,
        subject: subject(title)
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

    def import_source_user_reassign(source_user_id)
      @source_user = Import::SourceUser.find(source_user_id)
      @reassign_to_user = @source_user.reassign_to_user
      title = safe_format(
        s_('UserMapping|Reassignments on %{group} waiting for review.'),
        group: @source_user.namespace.full_path
      )

      email_with_layout(
        to: @reassign_to_user.notification_email_or_default,
        subject: subject(title)
      )
    end
  end
end
