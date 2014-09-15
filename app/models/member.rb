class Member < ActiveRecord::Base
  include Notifiable
  include Gitlab::Access

  belongs_to :user
  belongs_to :source, polymorphic: true

  validates :user, presence: true
  validates :source, presence: true
  validates :user_id, uniqueness: { scope: [:source_type, :source_id], message: "already exists in source" }
  validates :access_level, inclusion: { in: Gitlab::Access.all_values }, presence: true

  scope :guests, -> { where(access_level: GUEST) }
  scope :reporters, -> { where(access_level: REPORTER) }
  scope :developers, -> { where(access_level: DEVELOPER) }
  scope :masters,  -> { where(access_level: MASTER) }
  scope :owners,  -> { where(access_level: OWNER) }

  delegate :name, :username, :email, to: :user, prefix: true
end
