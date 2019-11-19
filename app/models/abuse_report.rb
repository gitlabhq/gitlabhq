# frozen_string_literal: true

class AbuseReport < ApplicationRecord
  include CacheMarkdownField
  include Sortable

  cache_markdown_field :message, pipeline: :single_line

  belongs_to :reporter, class_name: 'User'
  belongs_to :user

  validates :reporter, presence: true
  validates :user, presence: true
  validates :message, presence: true
  validates :user_id, uniqueness: { message: 'has already been reported' }

  scope :by_user, -> (user) { where(user_id: user) }
  scope :with_users, -> { includes(:reporter, :user) }

  # For CacheMarkdownField
  alias_method :author, :reporter

  def remove_user(deleted_by:)
    user.delete_async(deleted_by: deleted_by, params: { hard_delete: true })
  end

  def notify
    return unless self.persisted?

    AbuseReportMailer.notify(self.id).deliver_later
  end
end
