class NotificationSetting < ActiveRecord::Base
  belongs_to :user
  belongs_to :source, polymorphic: true

  validates :user, presence: true
  validates :source, presence: true
  validates :level, presence: true
  validates :user_id, uniqueness: { scope: [:source_type, :source_id],
                                    message: "already exists in source",
                                    allow_nil: true }
  # Notification level
  # Note: When adding an option, it MUST go on the end of the array.
  enum level: [:disabled, :participating, :watch, :global, :mention]

  scope :for_groups, -> { where(source_type: 'Namespace') }
  scope :for_projects, -> { where(source_type: 'Project') }

  def set_defaults
    self.level = :global
  end
end
