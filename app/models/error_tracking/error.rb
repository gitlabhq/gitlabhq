# frozen_string_literal: true

class ErrorTracking::Error < ApplicationRecord
  include Sortable

  belongs_to :project

  has_many :events, class_name: 'ErrorTracking::ErrorEvent'

  has_one :first_event,
    -> { order(id: :asc) },
    class_name: 'ErrorTracking::ErrorEvent'

  has_one :last_event,
    -> { order(id: :desc) },
    class_name: 'ErrorTracking::ErrorEvent'

  scope :for_status, ->(status) { where(status: status) }

  validates :project, presence: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 1024 }
  validates :actor, presence: true, length: { maximum: 255 }
  validates :platform, length: { maximum: 255 }
  validates :status, presence: true

  enum status: {
    unresolved: 0,
    resolved: 1,
    ignored: 2
  }

  def self.report_error(name:, description:, actor:, platform:, timestamp:)
    safe_find_or_create_by(
      name: name,
      actor: actor,
      platform: platform
    ).tap do |error|
      error.update!(
        # Description can contain object id, so it can't be
        # used as a group criteria for similar errors.
        description: description,
        last_seen_at: timestamp
      )
    end
  end

  def self.sort_by_attribute(method)
    case method.to_s
    when 'last_seen'
      order(last_seen_at: :desc)
    when 'first_seen'
      order(first_seen_at: :desc)
    when 'frequency'
      order(events_count: :desc)
    else
      order_id_desc
    end
  end

  def title
    if description.present?
      "#{name} #{description}"
    else
      name
    end
  end

  def title_truncated
    title.truncate(64)
  end

  # For compatibility with sentry integration
  def to_sentry_error
    Gitlab::ErrorTracking::Error.new(
      id: id,
      title: title_truncated,
      message: description,
      culprit: actor,
      first_seen: first_seen_at,
      last_seen: last_seen_at,
      status: status,
      count: events_count
    )
  end

  # For compatibility with sentry integration
  def to_sentry_detailed_error
    Gitlab::ErrorTracking::DetailedError.new(
      id: id,
      title: title_truncated,
      message: description,
      culprit: actor,
      first_seen: first_seen_at.to_s,
      last_seen: last_seen_at.to_s,
      count: events_count,
      user_count: 0, # we don't support user count yet.
      project_id: project.id,
      status: status,
      tags: { level: nil, logger: nil },
      external_url: external_url,
      external_base_url: external_base_url,
      integrated: true,
      first_release_version: first_event&.release,
      last_release_version: last_event&.release
    )
  end

  private

  # For compatibility with sentry integration
  def external_url
    Gitlab::Routing.url_helpers.details_namespace_project_error_tracking_index_url(
      namespace_id: project.namespace,
      project_id: project,
      issue_id: id)
  end

  # For compatibility with sentry integration
  def external_base_url
    Gitlab::Routing.url_helpers.project_url(project)
  end
end
