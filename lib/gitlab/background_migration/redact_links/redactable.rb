# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class RedactLinks
      module Redactable
        extend ActiveSupport::Concern

        def redact_field!(field)
          self[field].gsub!(%r{/sent_notifications/\h{32}/unsubscribe}, '/sent_notifications/REDACTED/unsubscribe')

          if self.changed?
            self.update_columns(field => self[field],
                                "#{field}_html" => nil)
          end
        end
      end
    end
  end
end
