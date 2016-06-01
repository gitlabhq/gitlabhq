class NotificationSetting < ActiveRecord::Base
  enum level: { global: 3, watch: 2, mention: 4, participating: 1, disabled: 0, custom: 5 }

  default_value_for :level, NotificationSetting.levels[:global]

  belongs_to :user
  belongs_to :source, polymorphic: true

  validates :user, presence: true
  validates :level, presence: true
  validates :user_id, uniqueness: { scope: [:source_type, :source_id],
                                    message: "already exists in source",
                                    allow_nil: true }

  scope :for_groups, -> { where(source_type: 'Namespace') }
  scope :for_projects, -> { where(source_type: 'Project') }

  EMAIL_EVENTS = [
    :new_note,
    :new_issue,
    :reopen_issue,
    :closed_issue,
    :reassign_issue,
    :new_merge_request,
    :reopen_merge_request,
    :close_merge_request,
    :reassign_merge_request,
    :merge_merge_request
  ]

  store :events, accessors: EMAIL_EVENTS, coder: JSON

  before_save :set_events

  def self.find_or_create_for(source)
    setting = find_or_initialize_by(source: source)

    unless setting.persisted?
      setting.save
    end

    setting
  end

  # Set all event attributes as true when level is not custom
  def set_events
    # Level is a ENUM cannot compare to symbol
    return if level == "custom"

    EMAIL_EVENTS.each do |event|
      self.send("#{event}=", true)
    end
  end
end
