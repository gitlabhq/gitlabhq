# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- TODO refactor to use bounded context
class Namespace::Detail < ApplicationRecord
  include CacheMarkdownField

  belongs_to :namespace, inverse_of: :namespace_details
  belongs_to :creator, class_name: "User", optional: true
  validates :namespace, presence: true
  validates :description, length: { maximum: 2000 }
  validates :state_metadata, json_schema: { filename: 'namespace_detail_state_metadata', size_limit: 64.kilobytes },
    if: :state_metadata_changed?

  ignore_column :deleted_at, remove_with: '18.11', remove_after: '2026-03-21'

  jsonb_accessor :state_metadata,
    last_updated_at: :datetime,
    last_changed_by_user_id: :integer,
    last_error: :string,
    deletion_scheduled_at: :datetime,
    deletion_scheduled_by_user_id: :integer

  cache_markdown_field :description, pipeline: :description

  self.primary_key = :namespace_id
end
# rubocop:enable Gitlab/BoundedContexts

Namespace::Detail.prepend_mod
