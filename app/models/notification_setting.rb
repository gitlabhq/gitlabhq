class NotificationSetting < ActiveRecord::Base
  enum level: { global: 3, watch: 2, mention: 4, participating: 1, disabled: 0, custom: 5 }

  default_value_for :level, NotificationSetting.levels[:global]

  belongs_to :user
  belongs_to :source, polymorphic: true
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
    includes(:project).references(:projects).where(source_type: 'Project').where.not(projects: { id: nil })
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
  ]

  store :events, accessors: EMAIL_EVENTS, coder: JSON

  before_create :set_events
  before_save :events_to_boolean

  def self.find_or_create_for(source)
    setting = find_or_initialize_by(source: source)

    unless setting.persisted?
      setting.save
    end

    setting
  end

  # Set all event attributes to false when level is not custom or being initialized for UX reasons
  def set_events
    return if custom?

    EMAIL_EVENTS.each do |event|
      events[event] = false
    end
  end

  # Validates store accessors values as boolean
  # It is a text field so it does not cast correct boolean values in JSON
  def events_to_boolean
    EMAIL_EVENTS.each do |event|
      events[event] = ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include?(events[event])
    end
  end
end
