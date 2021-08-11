# frozen_string_literal: true

class ErrorTracking::Error < ApplicationRecord
  belongs_to :project

  has_many :events, class_name: 'ErrorTracking::ErrorEvent'

  scope :for_status, -> (status) { where(status: status) }

  validates :project, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :actor, presence: true
  validates :status, presence: true

  enum status: {
    unresolved: 0,
    resolved: 1,
    ignored: 2
  }

  def self.report_error(name:, description:, actor:, platform:, timestamp:)
    safe_find_or_create_by(
      name: name,
      description: description,
      actor: actor,
      platform: platform
    ) do |error|
      error.update!(last_seen_at: timestamp)
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
      external_base_url: external_base_url
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
    Gitlab::Routing.url_helpers.root_url
  end
end
