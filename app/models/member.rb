class Member < ActiveRecord::Base
  include Notifiable
  include Gitlab::Access

  belongs_to :user
  belongs_to :source, polymorphic: true

  validates :user, presence: true
  validates :source, presence: true
  validates :user_id, uniqueness: { scope: [:source_type, :source_id], message: "already exists in source" }
  validates :access_level, inclusion: { in: Gitlab::Access.values }, presence: true

  scope :guests, -> { where(group_access: GUEST) }
  scope :reporters, -> { where(group_access: REPORTER) }
  scope :developers, -> { where(group_access: DEVELOPER) }
  scope :masters,  -> { where(group_access: MASTER) }
  scope :owners,  -> { where(group_access: OWNER) }
end
