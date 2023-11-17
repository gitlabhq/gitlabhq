# frozen_string_literal: true

module ActivityPub
  class ReleasesSubscription < ApplicationRecord
    belongs_to :project, optional: false

    enum :status, [:requested, :accepted], default: :requested

    attribute :payload, Gitlab::Database::Type::JsonPgSafe.new

    validates :payload, json_schema: { filename: 'activity_pub_follow_payload' }, allow_blank: true
    validates :subscriber_url, presence: true, uniqueness: { case_sensitive: false, scope: :project_id },
      public_url: true
    validates :subscriber_inbox_url, uniqueness: { case_sensitive: false, scope: :project_id, allow_nil: true },
      public_url: { allow_nil: true }
    validates :shared_inbox_url, public_url: { allow_nil: true }

    def self.find_by_project_and_subscriber(project_id, subscriber_url)
      find_by('project_id = ? AND LOWER(subscriber_url) = ?', project_id, subscriber_url.downcase)
    end
  end
end
