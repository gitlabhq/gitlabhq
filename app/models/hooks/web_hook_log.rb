# frozen_string_literal: true

class WebHookLog < ApplicationRecord
  include SafeUrl
  include Presentable
  include DeleteWithLimit
  include CreatedAtFilterable
  include PartitionedTable

  self.primary_key = :id

  partitioned_by :created_at, strategy: :monthly, retain_for: 3.months

  belongs_to :web_hook

  serialize :request_headers, Hash # rubocop:disable Cop/ActiveRecordSerialize
  serialize :request_data, Hash # rubocop:disable Cop/ActiveRecordSerialize
  serialize :response_headers, Hash # rubocop:disable Cop/ActiveRecordSerialize

  validates :web_hook, presence: true

  before_save :obfuscate_basic_auth
  before_save :redact_author_email

  def self.recent
    where('created_at >= ?', 2.days.ago.beginning_of_day)
      .order(created_at: :desc)
  end

  def success?
    response_status =~ /^2/
  end

  def internal_error?
    response_status == WebHookService::InternalErrorResponse::ERROR_MESSAGE
  end

  private

  def obfuscate_basic_auth
    self.url = safe_url
  end

  def redact_author_email
    return unless self.request_data.dig('commit', 'author', 'email').present?

    self.request_data['commit']['author']['email'] = _('[REDACTED]')
  end
end
