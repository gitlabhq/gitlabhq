# Sparkle Share invite system:
# See https://github.com/hbons/SparkleShare/wiki/Invites

class SparkleInvite < ActiveRecord::Base
  belongs_to :users_project

  has_one :user, through: :users_project
  has_one :project, through: :users_project

  validates :users_project, presence: true

  before_create :set_expire_at, :token

  DEFAULT_EXPIRE_WINDOW = 2.days

  def set_expire_at
    self.expire_at ||= DEFAULT_EXPIRE_WINDOW.from_now
  end

  def token
    super || (self.token = SecureRandom.hex(10))
  end

  def accept!(public_key)
    if acceptable?
      add_public_key_to_user(public_key)
      self.accepted_at = Time.now
      self.expire_at = nil
      self.save!
    end
  end

  # Attributes for the invite.xml file
  def address
    gitlab_shell = Gitlab.config.gitlab_shell
    "ssh://#{gitlab_shell.ssh_user}@#{gitlab_shell.ssh_host}:#{gitlab_shell.ssh_port}/"
  end

  def remote_path
    "/#{project.path_with_namespace}"
  end

  def fingerprint
    Gitlab.config.sparkle_share['fingerprint']
  end

  def announcements_url
    Gitlab.config.sparkle_share['announcements_url']
  end

  private
  def acceptable?
    self.accepted_at.nil? && (Time.now < self.expire_at)
  end

  def add_public_key_to_user(public_key)
    key = user.keys.find_by_key(public_key)
    key ||= user.keys.create!(key: public_key, title: 'SparkleShare')
  end
end
