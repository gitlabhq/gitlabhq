# frozen_string_literal: true

module ActivityPub
  class ReleasesSubscription < ApplicationRecord
    belongs_to :project, optional: false

    enum :status, [:requested, :accepted], default: :requested

    attribute :payload, Gitlab::Database::Type::JsonPgSafe.new

    validates :payload, json_schema: { filename: 'activity_pub_follow_payload' }, allow_blank: true
    validates :subscriber_url, presence: true, uniqueness: { case_sensitive: false, scope: :project_id },
      public_url: true
    validates :subscriber_inbox_url, uniqueness: { case_sensitive: false, scope: :project_id },
      public_url: { allow_nil: true }
    validates :shared_inbox_url, public_url: { allow_nil: true }

    def self.find_by_subscriber_url(subscriber_url)
      find_by('LOWER(subscriber_url) = ?', subscriber_url.downcase)
    end
  end
end
