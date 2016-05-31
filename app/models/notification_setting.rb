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

  serialize :events

  EMAIL_EVENTS = [
    :new_issue_email,
    :new_note_email,
    :closed_issue_email,
    :reassigned_issue_email,
    :relabeled_issue_email,
    :new_merge_request_email,
    :reassigned_merge_request_email,
    :relabeled_merge_request_email,
    :closed_merge_request_email,
    :issue_status_changed_email,
    :merged_merge_request_email,
    :merge_request_status_email
  ]

  before_save :set_events

  def self.find_or_create_for(source)
    setting = find_or_initialize_by(source: source)

    unless setting.persisted?
      setting.save
    end

    setting
  end

  def set_events
    self.events = EMAIL_EVENTS if level == "watch"
  end
end
