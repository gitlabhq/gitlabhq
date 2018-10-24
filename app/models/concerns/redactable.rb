# frozen_string_literal: true

# This module searches and redacts sensitive information in
# redactable fields. Currently only unsubscribe link is redacted.
# Add following lines into your model:
#
#     include Redactable
#     redact_field :foo
#
module Redactable
  extend ActiveSupport::Concern

  UNSUBSCRIBE_PATTERN = %r{/sent_notifications/\h{32}/unsubscribe}

  class_methods do
    def redact_field(field)
      before_validation do
        redact_field!(field) if attribute_changed?(field)
      end
    end
  end

  private

  def redact_field!(field)
    text = public_send(field) # rubocop:disable GitlabSecurity/PublicSend
    return unless text.present?

    redacted = text.gsub(UNSUBSCRIBE_PATTERN, '/sent_notifications/REDACTED/unsubscribe')

    public_send("#{field}=", redacted) # rubocop:disable GitlabSecurity/PublicSend
  end
end
