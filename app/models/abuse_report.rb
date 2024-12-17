# frozen_string_literal: true

class AbuseReport < ApplicationRecord
  ignore_column :assignee_id_convert_to_bigint, remove_with: '17.9', remove_after: '2025-01-16'
  ignore_column :id_convert_to_bigint, remove_with: '17.9', remove_after: '2025-01-16'
  ignore_column :reporter_id_convert_to_bigint, remove_with: '17.9', remove_after: '2025-01-16'
  ignore_column :resolved_by_id_convert_to_bigint, remove_with: '17.9', remove_after: '2025-01-16'
  ignore_column :user_id_convert_to_bigint, remove_with: '17.9', remove_after: '2025-01-16'

  include CacheMarkdownField
  include Sortable
  include Gitlab::FileTypeDetection
  include WithUploads
  include Gitlab::Utils::StrongMemoize
  include Mentionable
  include Noteable

  ignore_column :assignee_id, remove_with: '16.9', remove_after: '2024-01-19'

  MAX_CHAR_LIMIT_URL = 512
  MAX_FILE_SIZE = 1.megabyte

  cache_markdown_field :message, pipeline: :single_line

  belongs_to :reporter, class_name: 'User', inverse_of: :reported_abuse_reports
  belongs_to :user, inverse_of: :abuse_reports
  belongs_to :resolved_by, class_name: 'User', inverse_of: :resolved_abuse_reports

  has_many :events, class_name: 'ResourceEvents::AbuseReportEvent', inverse_of: :abuse_report
  has_many :label_links, inverse_of: :abuse_report, class_name: 'AntiAbuse::Reports::LabelLink'
  has_many :labels, through: :label_links, source: :abuse_report_label,
    class_name: 'AntiAbuse::Reports::Label'
  has_many :admin_abuse_report_assignees, class_name: "Admin::AbuseReportAssignee"
  has_many :assignees, class_name: "User", through: :admin_abuse_report_assignees

  has_many :abuse_events, class_name: 'AntiAbuse::Event', inverse_of: :abuse_report

  has_many :notes, class_name: 'AntiAbuse::Reports::Note'
  has_many :user_mentions, class_name: 'AntiAbuse::Reports::UserMention'

  validates :reporter, presence: true, on: :create
  validates :user, presence: true, on: :create
  validates :message, presence: true
  validates :category, presence: true
  validates :user_id,
    uniqueness: {
      scope: [:reporter_id, :category],
      message: ->(object, data) do
        _('You have already reported this user')
      end
    }, on: :create

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

  validates :mitigation_steps, length: { maximum: 1000 }, allow_blank: true
  validates :evidence, json_schema: { filename: 'abuse_report_evidence' }, allow_blank: true

  before_validation :filter_empty_strings_from_links_to_spam
  validate :links_to_spam_contains_valid_urls

  mount_uploader :screenshot, AttachmentUploader
  validates :screenshot, file_size: { maximum: MAX_FILE_SIZE }
  validate :validate_screenshot_is_image

  scope :by_user_id, ->(user_id) { where(user_id: user_id) }
  scope :by_reporter_id, ->(reporter_id) { where(reporter_id: reporter_id) }
  scope :by_category, ->(category) { where(category: category) }
  scope :with_users, -> { includes(:reporter, :user) }
  scope :with_labels, -> { includes(:labels) }

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

  CONTROLLER_TO_REPORT_TYPE = {
    'users' => :profile,
    'projects/issues' => :issue,
    'projects/merge_requests' => :merge_request
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

  def screenshot_path
    return unless screenshot
    return screenshot.url unless screenshot.upload

    asset_host = ActionController::Base.asset_host || Gitlab.config.gitlab.base_url
    local_path = Gitlab::Routing.url_helpers.abuse_report_screenshot_path(
      filename: screenshot.filename,
      id: screenshot.upload.model_id,
      model: 'abuse_report',
      mounted_as: 'screenshot')

    Gitlab::Utils.append_path(asset_host, local_path)
  end

  def report_type
    type = CONTROLLER_TO_REPORT_TYPE[route_hash[:controller]]
    type = :comment if type.in?([:issue, :merge_request]) && note_id_from_url.present?

    type
  end

  def reported_content
    case report_type
    when :issue
      reported_project.issues.iid_in(route_hash[:id]).pick(:description_html)
    when :merge_request
      reported_project.merge_requests.iid_in(route_hash[:id]).pick(:description_html)
    when :comment
      reported_project.notes.id_in(note_id_from_url).pick(:note_html)
    end
  end

  def past_closed_reports_for_user
    user.abuse_reports.closed.id_not_in(id)
  end

  def similar_open_reports_for_user
    return AbuseReport.none unless open?

    user.abuse_reports.open.by_category(category).id_not_in(id).includes(:reporter)
  end

  # createNote mutation calls noteable.project,
  # which in case of abuse reports is nil
  def project
    nil
  end

  def uploads_sharding_key
    {}
  end

  private

  def reported_project
    Project.find_by_full_path(route_hash.values_at(:namespace_id, :project_id).join('/'))
  end

  def reported_group
    Group.find_by_full_path(route_hash[:group_id])
  end

  def route_hash
    match = Rails.application.routes.recognize_path(reported_from_url)
    return {} if match[:unmatched_route].present?

    match
  rescue ActionController::RoutingError
    {}
  end
  strong_memoize_attr :route_hash

  def note_id_from_url
    fragment = URI(reported_from_url).fragment
    Gitlab::UntrustedRegexp.new('^note_(\d+)$').match(fragment).to_a.second if fragment
  rescue URI::InvalidURIError
    nil
  end
  strong_memoize_attr :note_id_from_url

  def filter_empty_strings_from_links_to_spam
    return if links_to_spam.blank?

    links_to_spam.reject!(&:empty?)
  end

  def links_to_spam_contains_valid_urls
    return if links_to_spam.blank?

    links_to_spam.each do |link|
      Gitlab::HTTP_V2::UrlBlocker.validate!(
        link,
        schemes: %w[http https],
        allow_localhost: true,
        dns_rebind_protection: true,
        deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
        outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist) # rubocop:disable Naming/InclusiveLanguage -- existing setting

      next unless link.length > MAX_CHAR_LIMIT_URL

      errors.add(
        :links_to_spam,
        format(_('contains URLs that exceed the %{limit} character limit'), limit: MAX_CHAR_LIMIT_URL)
      )
    end
  rescue ::Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError
    errors.add(:links_to_spam, _('only supports valid HTTP(S) URLs'))
  end

  def filename
    screenshot&.filename
  end

  def valid_image_extensions
    Gitlab::FileTypeDetection::SAFE_IMAGE_EXT
  end

  def validate_screenshot_is_image
    return if screenshot.blank?
    return if image?

    errors.add(
      :screenshot,
      format(
        _('must match one of the following file types: %{extension_list}'),
        extension_list: valid_image_extensions.to_sentence(last_word_connector: ' or '))
    )
  end

  def self.aggregated_by_user_and_category(sort_by_count = false)
    sub_query = self
      .select('user_id, category, COUNT(id) as count', 'MIN(id) as min')
      .group(:user_id, :category)

    reports = AbuseReport.with_users
      .open
      .select('aggregated.*, status, id, reporter_id, created_at, updated_at')
      .from(sub_query, :aggregated)
      .joins('INNER JOIN abuse_reports on aggregated.min = abuse_reports.id')

    if sort_by_count
      reports.order(count: :desc, created_at: :desc)
    else
      reports
    end
  end
end

AbuseReport.prepend_mod
