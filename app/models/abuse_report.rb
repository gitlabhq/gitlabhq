# frozen_string_literal: true

class AbuseReport < ApplicationRecord
  include CacheMarkdownField
  include Sortable

  MAX_CHAR_LIMIT_URL = 512

  cache_markdown_field :message, pipeline: :single_line

  belongs_to :reporter, class_name: 'User'
  belongs_to :user

  validates :reporter, presence: true
  validates :user, presence: true
  validates :message, presence: true
  validates :category, presence: true
  validates :user_id,
    uniqueness: {
      scope: [:reporter_id, :category],
      message: ->(object, data) do
        _('You have already reported this user')
      end
    }

  validates :reported_from_url,
            allow_blank: true,
            length: { maximum: MAX_CHAR_LIMIT_URL },
            addressable_url: {
              dns_rebind_protection: true,
              blocked_message: 'is an invalid URL. You can try reporting the abuse again, ' \
                               'or contact a GitLab administrator for help.'
            }

  validates :links_to_spam,
            allow_blank: true,
            length: {
              maximum: 20,
              message: N_("exceeds the limit of %{count} links")
            }

  before_validation :filter_empty_strings_from_links_to_spam
  validate :links_to_spam_contains_valid_urls

  scope :by_user_id, ->(id) { where(user_id: id) }
  scope :by_category, ->(category) { where(category: category) }
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

  enum status: {
    open: 1,
    closed: 2
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
    return unless persisted?

    AbuseReportMailer.notify(id).deliver_later
  end

  private

  def filter_empty_strings_from_links_to_spam
    return if links_to_spam.blank?

    links_to_spam.reject!(&:empty?)
  end

  def links_to_spam_contains_valid_urls
    return if links_to_spam.blank?

    links_to_spam.each do |link|
      Gitlab::UrlBlocker.validate!(
        link,
          schemes: %w[http https],
          allow_localhost: true,
          dns_rebind_protection: true
      )

      next unless link.length > MAX_CHAR_LIMIT_URL

      errors.add(
        :links_to_spam,
        format(_('contains URLs that exceed the %{limit} character limit'), limit: MAX_CHAR_LIMIT_URL)
      )
    end
  rescue ::Gitlab::UrlBlocker::BlockedUrlError
    errors.add(:links_to_spam, _('only supports valid HTTP(S) URLs'))
  end
end
