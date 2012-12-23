# == Schema Information
#
# Table name: namespaces
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  path       :string(255)      not null
#  owner_id   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string(255)
#

class Namespace < ActiveRecord::Base
  attr_accessible :name, :path

  has_many :projects, dependent: :destroy
  belongs_to :owner, class_name: "User"

  validates :name, presence: true, uniqueness: true
  validates :path, uniqueness: true, presence: true, length: { within: 1..255 },
            format: { with: Gitlab::Regex.path_regex,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }
  validates :owner, presence: true

  delegate :name, to: :owner, allow_nil: true, prefix: true

  after_create :ensure_dir_exist
  after_update :move_dir
  after_destroy :rm_dir

  scope :root, where('type IS NULL')

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
    namespace_dir_path = File.join(Gitlab.config.gitolite.repos_path, path)
    system("mkdir -m 770 #{namespace_dir_path}") unless File.exists?(namespace_dir_path)
  end

  def move_dir
    if path_changed?
      old_path = File.join(Gitlab.config.gitolite.repos_path, path_was)
      new_path = File.join(Gitlab.config.gitolite.repos_path, path)
      if File.exists?(new_path)
        raise "Already exists"
      end

      if system("mv #{old_path} #{new_path}")
        send_update_instructions
      end
    end
  end

  def rm_dir
    dir_path = File.join(Gitlab.config.gitolite.repos_path, path)
    system("rm -rf #{dir_path}")
  end

  def send_update_instructions
    projects.each(&:send_move_instructions)
  end
end
