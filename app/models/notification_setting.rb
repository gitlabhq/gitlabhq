# frozen_string_literal: true

class NotificationSetting < ApplicationRecord
  include FromUnion

  enum level: { global: 3, watch: 2, participating: 1, mention: 4, disabled: 0, custom: 5 }

  default_value_for :level, NotificationSetting.levels[:global]

  belongs_to :user
  belongs_to :source, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :project, foreign_key: 'source_id'

  validates :user, presence: true
  validates :level, presence: true
  validates :user_id, uniqueness: { scope: [:source_type, :source_id],
                                    message: "already exists in source",
                                    allow_nil: true }
  validate :owns_notification_email, if: :notification_email_changed?

  scope :for_groups, -> { where(source_type: 'Namespace') }

  # Exclude projects not included by the Project model's default scope (those that are
  # pending delete).
  #
  scope :for_projects, -> do
    includes(:project).references(:projects)
      .where(source_type: 'Project')
      .where.not(projects: { id: nil })
      .where.not(projects: { pending_delete: true })
  end

  scope :preload_source_route, -> { preload(source: [:route]) }

  scope :order_by_id_asc, -> { order(id: :asc) }

  # NOTE: Applicable unfound_translations.rb also needs to be updated when below events are changed.
  EMAIL_EVENTS = [
    :new_release,
    :new_note,
    :new_issue,
    :reopen_issue,
    :close_issue,
    :reassign_issue,
    :issue_due,
    :new_merge_request,
    :push_to_merge_request,
    :reopen_merge_request,
    :close_merge_request,
    :reassign_merge_request,
    :change_reviewer_merge_request,
    :merge_merge_request,
    :failed_pipeline,
    :fixed_pipeline,
    :success_pipeline,
    :moved_project,
    :merge_when_pipeline_succeeds
  ].freeze

  def self.email_events(source = nil)
    EMAIL_EVENTS
  end

  def self.allowed_fields(source = nil)
    NotificationSetting.email_events(source).dup + %i(level notification_email)
  end

  def email_events
    self.class.email_events(source)
  end

  EXCLUDED_WATCHER_EVENTS = [
    :push_to_merge_request,
    :issue_due,
    :success_pipeline
  ].freeze

  def self.find_or_create_for(source)
    setting = find_or_initialize_by(source: source)

    unless setting.persisted?
      setting.save
    end

    setting
  end

  # Allow people to receive both failed pipeline/fixed pipeline notifications
  # if they already have custom notifications enabled,
  # as these are more like mentions than the other custom settings.
  def failed_pipeline
    bool = super

    bool.nil? || bool
  end
  alias_method :failed_pipeline?, :failed_pipeline

  def fixed_pipeline
    bool = super

    bool.nil? || bool
  end
  alias_method :fixed_pipeline?, :fixed_pipeline

  def event_enabled?(event)
    # We override these two attributes, so we can't use read_attribute
    return failed_pipeline if event.to_sym == :failed_pipeline
    return fixed_pipeline if event.to_sym == :fixed_pipeline

    has_attribute?(event) && !!read_attribute(event)
  end

  def owns_notification_email
    return if user.temp_oauth_email?
    return if notification_email.empty?

    errors.add(:notification_email, _("is not an email you own")) unless user.verified_emails.include?(notification_email)
  end
end

NotificationSetting.prepend_mod_with('NotificationSetting')
