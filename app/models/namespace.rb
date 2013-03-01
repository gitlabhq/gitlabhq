# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  description :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string(255)
#

class Namespace < ActiveRecord::Base
  attr_accessible :name, :description, :path

  has_many :projects, dependent: :destroy
  belongs_to :owner, class_name: "User"

  validates :owner, presence: true
  validates :name, presence: true, uniqueness: true,
            length: { within: 0..255 },
            format: { with: Gitlab::Regex.name_regex,
                      message: "only letters, digits, spaces & '_' '-' '.' allowed." }
  validates :description, length: { within: 0..255 }
  validates :path, uniqueness: true, presence: true, length: { within: 1..255 },
            format: { with: Gitlab::Regex.path_regex,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }

  delegate :name, to: :owner, allow_nil: true, prefix: true

  after_create :ensure_dir_exist
  after_update :move_dir
  after_destroy :rm_dir

  scope :root, -> { where('type IS NULL') }

  def self.search query
    where("name LIKE :query OR path LIKE :query", query: "%#{query}%")
  end

  def self.global_id
    'GLN'
  end

  def to_param
    path
  end

  def human_name
    owner_name
  end

  def ensure_dir_exist
    unless dir_exists?
      FileUtils.mkdir( namespace_full_path, mode: 0770 )
    end
  end

  def dir_exists?
    File.exists?(namespace_full_path)
  end

  def namespace_full_path
    @namespace_full_path ||= File.join(Gitlab.config.gitlab_shell.repos_path, path)
  end

  def move_dir
    if path_changed?
      old_path = File.join(Gitlab.config.gitlab_shell.repos_path, path_was)
      new_path = File.join(Gitlab.config.gitlab_shell.repos_path, path)
      if File.exists?(new_path)
        raise "Already exists"
      end


      begin
        # Remove satellite when moving repo
        if path_was.present?
          satellites_path = File.join(Gitlab.config.satellites.path, path_was)
          FileUtils.rm_r( satellites_path, force: true )
        end

        FileUtils.mv( old_path, new_path )
        send_update_instructions
      rescue Exception => e
        raise "Namespace move error #{old_path} #{new_path}"
      end
    end
  end

  def rm_dir
    dir_path = File.join(Gitlab.config.gitlab_shell.repos_path, path)
    FileUtils.rm_r( dir_path, force: true )
  end

  def send_update_instructions
    projects.each(&:send_move_instructions)
  end
end
