# frozen_string_literal: true

class PopulateAuditEventStreamingVerificationToken < Gitlab::Database::Migration[1.0]
  class ExternalAuditEventDestination < ActiveRecord::Base
    self.table_name = 'audit_events_external_audit_event_destinations'

    def regenerate_verification_token
      update!(verification_token: SecureRandom.base58(24))
    end
  end

  def up
    ExternalAuditEventDestination.all.each { |destination| destination.regenerate_verification_token }
  end

  def down
    # no-op
  end
end
