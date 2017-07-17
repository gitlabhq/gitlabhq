class NotificationSetting < ApplicationRecord
  enum level: { global: 3, watch: 2, mention: 4, participating: 1, disabled: 0, custom: 5 }

  default_value_for :level, NotificationSetting.levels[:global]

  belongs_to :user
  belongs_to :source, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :project, foreign_key: 'source_id'

  validates :user, presence: true
  validates :level, presence: true
  validates :user_id, uniqueness: { scope: [:source_type, :source_id],
                                    message: "already exists in source",
                                    allow_nil: true }

  scope :for_groups, -> { where(source_type: 'Namespace') }

  # Exclude projects not included by the Project model's default scope (those that are
  # pending delete).
  #
  scope :for_projects, -> do
    includes(:project).references(:projects).where(source_type: 'Project').where.not(projects: { id: nil, pending_delete: true })
  end

  EMAIL_EVENTS = [
    :new_note,
    :new_issue,
    :reopen_issue,
    :close_issue,
    :reassign_issue,
    :new_merge_request,
    :reopen_merge_request,
    :close_merge_request,
    :reassign_merge_request,
    :merge_merge_request,
    :failed_pipeline,
    :success_pipeline
  ].freeze

  EXCLUDED_WATCHER_EVENTS = [
    :success_pipeline
  ].freeze

  store :events, coder: JSON
  before_save :convert_events

  def self.find_or_create_for(source)
    setting = find_or_initialize_by(source: source)

    unless setting.persisted?
      setting.save
    end

    setting
  end

  # 1. Check if this event has a value stored in its database column.
  # 2. If it does, return that value.
  # 3. If it doesn't (the value is nil), return the value from the serialized
  #    JSON hash in `events`.
  (EMAIL_EVENTS - [:failed_pipeline]).each do |event|
    define_method(event) do
      bool = super()

      bool.nil? ? !!events[event] : bool
    end

    alias_method :"#{event}?", event
  end

  # Allow people to receive failed pipeline notifications if they already have
  # custom notifications enabled, as these are more like mentions than the other
  # custom settings.
  def failed_pipeline
    bool = super
    bool = events[:failed_pipeline] if bool.nil?

    bool.nil? || bool
  end
  alias_method :failed_pipeline?, :failed_pipeline

  def event_enabled?(event)
    respond_to?(event) && public_send(event)
  end

  def convert_events
    return if events_before_type_cast.nil?

    EMAIL_EVENTS.each do |event|
      write_attribute(event, public_send(event))
    end

    write_attribute(:events, nil)
  end
end
