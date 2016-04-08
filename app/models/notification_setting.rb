class NotificationSetting < ActiveRecord::Base
  # Notification level
  # Note: When adding an option, it MUST go on the end of the array.
  enum level: [:disabled, :participating, :watch, :global, :mention]

  default_value_for :level, NotificationSetting.levels[:global]

  belongs_to :user
  belongs_to :source, polymorphic: true

  validates :user, presence: true
  validates :source, presence: true
  validates :level, presence: true
  validates :user_id, uniqueness: { scope: [:source_type, :source_id],
                                    message: "already exists in source",
                                    allow_nil: true }

  scope :for_groups, -> { where(source_type: 'Namespace') }
  scope :for_projects, -> { where(source_type: 'Project') }

  def self.find_or_create_for(source)
    setting = find_or_initialize_by(source: source)

    unless setting.persisted?
      setting.save
    end

    setting
  end
end
