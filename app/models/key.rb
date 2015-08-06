# == Schema Information
#
# Table name: keys
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  created_at  :datetime
#  updated_at  :datetime
#  key         :text
#  title       :string(255)
#  type        :string(255)
#  fingerprint :string(255)
#  public      :boolean          default(FALSE), not null
#

require 'digest/md5'

class Key < ActiveRecord::Base
  include Sortable

  belongs_to :user

  before_validation :strip_white_space, :generate_fingerprint

  validates :title, presence: true, length: { within: 0..255 }
  validates :key, presence: true, length: { within: 0..5000 }, format: { with: /\A(ssh|ecdsa)-.*\Z/ }, uniqueness: true
  validates :key, format: { without: /\n|\r/, message: 'should be a single line' }
  validates :fingerprint, uniqueness: true, presence: { message: 'cannot be generated' }

  delegate :name, :email, to: :user, prefix: true

  after_create :add_to_shell
  after_create :notify_user
  after_create :post_create_hook
  after_destroy :remove_from_shell
  after_destroy :post_destroy_hook

  def strip_white_space
    self.key = key.strip unless key.blank?
  end

  def publishable_key
    #Removes anything beyond the keytype and key itself
    self.key.split[0..1].join(' ')
  end

  # projects that has this key
  def projects
    user.authorized_projects
  end

  def shell_id
    "key-#{id}"
  end

  def add_to_shell
    GitlabShellWorker.perform_async(
      :add_key,
      shell_id,
      key
    )
  end

  def notify_user
    NotificationService.new.new_key(self)
  end

  def post_create_hook
    SystemHooksService.new.execute_hooks_for(self, :create)
  end

  def remove_from_shell
    GitlabShellWorker.perform_async(
      :remove_key,
      shell_id,
      key,
    )
  end

  def post_destroy_hook
    SystemHooksService.new.execute_hooks_for(self, :destroy)
  end

  private

  def generate_fingerprint
    self.fingerprint = nil

    return unless self.key.present?

    self.fingerprint = Gitlab::KeyFingerprint.new(self.key).fingerprint
  end
end
