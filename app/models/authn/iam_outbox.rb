# frozen_string_literal: true

module Authn
  class IamOutbox < ApplicationRecord
    self.table_name = 'iam_outbox'

    ALLOWED_ENTITY_TYPES = %w[oauth_application].freeze

    belongs_to :organization, class_name: 'Organizations::Organization', optional: false

    # `scopes: false` avoids generating `upsert`/`delete` class scopes, which would
    # collide with ActiveRecord's own `upsert` and `delete` class methods.
    enum :event_type, { upsert: 0, delete: 1 }, scopes: false

    validates :entity_type, presence: true, inclusion: { in: ALLOWED_ENTITY_TYPES }
    validates :entity_id, presence: true
    validates :event_type, presence: true
    validates :payload, json_schema: { filename: 'iam_outbox_payload', size_limit: 64.kilobytes }

    scope :l0_undelivered, -> { where(l0_delivered_at: nil) }
    scope :l2_undelivered, -> { where(l2_delivered_at: nil) }
  end
end
