# frozen_string_literal: true

class WebHookLog < ApplicationRecord
  include SafeUrl
  include Presentable

  belongs_to :web_hook

  serialize :request_headers, Hash # rubocop:disable Cop/ActiveRecordSerialize
  serialize :request_data, Hash # rubocop:disable Cop/ActiveRecordSerialize
  serialize :response_headers, Hash # rubocop:disable Cop/ActiveRecordSerialize

  validates :web_hook, presence: true

  before_save :obfuscate_basic_auth

  def self.recent
    where('created_at >= ?', 2.days.ago.beginning_of_day)
      .order(created_at: :desc)
  end

  def success?
    response_status =~ /^2/
  end

  private

  def obfuscate_basic_auth
    self.url = safe_url
  end
end
