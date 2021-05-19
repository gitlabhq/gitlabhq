# frozen_string_literal: true

class PushEventPayload < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  include ShaAttribute

  belongs_to :event, inverse_of: :push_event_payload

  validates :event_id, :commit_count, :action, :ref_type, presence: true
  validates :commit_title, length: { maximum: 70 }

  sha_attribute :commit_from
  sha_attribute :commit_to

  enum action: {
    created: 0,
    removed: 1,
    pushed: 2
  }

  enum ref_type: {
    branch: 0,
    tag: 1
  }
end

PushEventPayload.prepend_mod_with('PushEventPayload')
