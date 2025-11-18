# frozen_string_literal: true

class WebHookLog < ApplicationRecord
  include Presentable
  include DeleteWithLimit
  include CreatedAtFilterable
  include PartitionedTable

  OVERSIZE_REQUEST_DATA = { 'oversize' => true }.freeze
  MAX_RECENT_DAYS = 7

  attr_accessor :interpolated_url

  self.primary_key = :id
  self.table_name = :web_hook_logs_daily
  partitioned_by :created_at, strategy: :daily, retain_for: 14.days

  belongs_to :web_hook

  serialize :request_headers, type: Hash # rubocop:disable Cop/ActiveRecordSerialize
  serialize :request_data, type: Hash # rubocop:disable Cop/ActiveRecordSerialize
  serialize :response_headers, type: Hash # rubocop:disable Cop/ActiveRecordSerialize

  validates :web_hook, presence: true

  before_save :obfuscate_basic_auth
  before_save :redact_user_emails
  before_save :set_url_hash, if: -> { interpolated_url.present? }

  scope :by_status_code, ->(status_code) { where(response_status: status_code) }

  def self.recent(number_of_days = 2)
    if number_of_days > MAX_RECENT_DAYS
      raise ArgumentError,
        "`recent` scope can only provide up to #{MAX_RECENT_DAYS} days of log records"
    end

    created_between(number_of_days.days.ago.beginning_of_day, Time.zone.now)
  end

  def self.created_between(start_time, end_time)
    raise ArgumentError, '`start_time` and `end_time` must be present' if start_time.blank? || end_time.blank?

    raise ArgumentError, '`start_time` must be before `end_time`' if start_time > end_time

    if max_recent_days_ago > start_time
      raise ArgumentError, "`start_time` to `end_time` range must be within the last #{MAX_RECENT_DAYS} days"
    end

    where(created_at: start_time..end_time).order(created_at: :desc)
  end

  # Delete a batch of log records. Returns true if there may be more remaining.
  def self.delete_batch_for(web_hook, batch_size:)
    raise ArgumentError, 'batch_size is too small' if batch_size < 1

    where(web_hook: web_hook).limit(batch_size).delete_all == batch_size
  end

  def self.max_recent_days_ago
    WebHookLog::MAX_RECENT_DAYS.days.ago.beginning_of_day
  end

  def success?
    response_status =~ /^2/
  end

  def internal_error?
    response_status == WebHookService::InternalErrorResponse::ERROR_MESSAGE
  end

  def oversize?
    request_data == OVERSIZE_REQUEST_DATA
  end

  def request_headers
    return super unless self[:request_headers]['X-Gitlab-Token']

    self[:request_headers].merge('X-Gitlab-Token' => _('[REDACTED]'))
  end

  def request_headers_list
    list_headers(request_headers)
  end

  def response_headers_list
    list_headers(response_headers)
  end

  def idempotency_key
    self[:request_headers]['Idempotency-Key']
  end

  def url_current?
    # URL hash hasn't been set, so we must assume there's no prior value to
    # compare to.
    return true if url_hash.nil?

    Gitlab::CryptoHelper.sha256(web_hook.interpolated_url) == url_hash
  end

  private

  def obfuscate_basic_auth
    self.url = Gitlab::UrlSanitizer.sanitize_masked_url(url)
  end

  def redact_user_emails
    self.request_data.deep_transform_values! do |value|
      URI::MailTo::EMAIL_REGEXP.match?(value.to_s) ? _('[REDACTED]') : value
    end
  end

  def set_url_hash
    self.url_hash = Gitlab::CryptoHelper.sha256(interpolated_url)
  end

  def list_headers(headers_hash)
    return [] unless headers_hash.present?

    headers_hash.map do |header_name, header_value|
      { name: header_name, value: header_value }
    end
  end
end
