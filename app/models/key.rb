# == Schema Information
#
# Table name: keys
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  key        :text
#  title      :string(255)
#  identifier :string(255)
#  type       :string(255)
#

require 'digest/md5'

class Key < ActiveRecord::Base
  include Gitlab::Popen

  belongs_to :user

  attr_accessible :key, :title

  before_validation :strip_white_space

  validates :title, presence: true, length: { within: 0..255 }
  validates :key, presence: true, length: { within: 0..5000 }, format: { with: /\A(ssh|ecdsa)-.*\Z/ }, uniqueness: true
  validate :fingerprintable_key

  delegate :name, :email, to: :user, prefix: true

  def strip_white_space
    self.key = key.strip unless key.blank?
  end

  def fingerprintable_key
    return true unless key # Don't test if there is no key.

    unless generate_fingerpint
      errors.add(:key, "can't be fingerprinted")
      false
    end
  end

  # projects that has this key
  def projects
    user.authorized_projects
  end

  def shell_id
    "key-#{id}"
  end

  private

  def generate_fingerpint
    cmd_status = 0
    cmd_output = ''
    file = Tempfile.new('gitlab_key_file')

    begin
      file.puts key
      file.rewind
      cmd_output, cmd_status = popen("ssh-keygen -lf #{file.path}", '/tmp')
    ensure
      file.close
      file.unlink # deletes the temp file
    end

    if cmd_status.zero?
      cmd_output.gsub /([\d\h]{2}:)+[\d\h]{2}/ do |match|
        self.fingerprint = match
      end
      true
    else
      false
    end
  end
end
