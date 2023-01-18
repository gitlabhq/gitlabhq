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
  end
end
