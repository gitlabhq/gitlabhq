# frozen_string_literal: true

module Gitlab
  module Email
    module Hook
      class EmailTemplateInterceptor
        ##
        # Remove HTML part if HTML emails are disabled.
        #
        def self.delivering_email(message)
          unless Gitlab::CurrentSettings.html_emails_enabled
            message.parts.delete_if do |part|
              part.content_type.start_with?('text/html')
            end
          end
        end
      end
    end
  end
end
