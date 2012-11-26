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
            format: { with: /\A[a-zA-Z][a-zA-Z0-9_\-\.]*\z/,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }
  validates :owner, presence: true

  delegate :name, to: :owner, allow_nil: true, prefix: true

  after_create :ensure_dir_exist
  after_update :move_dir

  scope :root, where('type IS NULL')

  def self.search query
    where("name LIKE :query OR path LIKE :query", query: "%#{query}%")
  end

  def to_param
    path
  end

  def human_name
    owner_name
  end

  def ensure_dir_exist
    namespace_dir_path = File.join(Gitlab.config.git_base_path, path)
    Dir.mkdir(namespace_dir_path, 0770) unless File.exists?(namespace_dir_path)
  end

  def move_dir
    old_path = File.join(Gitlab.config.git_base_path, path_was)
    new_path = File.join(Gitlab.config.git_base_path, path)
    system("mv #{old_path} #{new_path}")
  end
end
