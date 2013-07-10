# == Schema Information
#
# Table name: keys
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  key        :text
#  title      :string(255)
#  identifier :string(255)
#  project_id :integer
#

require 'digest/md5'

class Key < ActiveRecord::Base
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

    file = Tempfile.new('key_file')
    begin
      file.puts key
      file.rewind
      fingerprint_output = `ssh-keygen -lf #{file.path} 2>&1` # Catch stderr.
    ensure
      file.close
      file.unlink # deletes the temp file
    end
    errors.add(:key, "can't be fingerprinted") if $?.exitstatus != 0
  end

  # projects that has this key
  def projects
    user.authorized_projects
  end

  def shell_id
    "key-#{id}"
  end
end
