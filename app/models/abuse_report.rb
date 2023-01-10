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
  validates :category, presence: true
  validates :user_id,
    uniqueness: {
      scope: :reporter_id,
      message: ->(object, data) do
        _('has already been reported for abuse')
      end
    }

  validates :reported_from_url,
            allow_blank: true,
            length: { maximum: 512 },
            addressable_url: {
              dns_rebind_protection: true,
              blocked_message: 'is an invalid URL. You can try reporting the abuse again, ' \
                               'or contact a GitLab administrator for help.'
            }

  scope :by_user, ->(user) { where(user_id: user) }
  scope :with_users, -> { includes(:reporter, :user) }

  enum category: {
    spam: 1,
    offensive: 2,
    phishing: 3,
    crypto: 4,
    credentials: 5,
    copyright: 6,
    malware: 7,
    other: 8
  }

  # For CacheMarkdownField
  alias_method :author, :reporter

  HUMANIZED_ATTRIBUTES = {
    reported_from_url: "Reported from"
  }.freeze

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def remove_user(deleted_by:)
    user.delete_async(deleted_by: deleted_by, params: { hard_delete: true })
  end

  def notify
    return unless self.persisted?

    AbuseReportMailer.notify(self.id).deliver_later
  end
end
