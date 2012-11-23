class Namespace < ActiveRecord::Base
  attr_accessible :code, :name, :owner_id

  has_many :projects
  belongs_to :owner, class_name: "User"

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
  validates :owner, presence: true

  delegate :name, to: :owner, allow_nil: true, prefix: true

  after_save :ensure_dir_exist

  scope :root, where('type IS NULL')

  def self.search query
    where("name LIKE :query OR code LIKE :query", query: "%#{query}%")
  end

  def to_param
    code
  end

  def human_name
    owner_name
  end

  def ensure_dir_exist
    namespace_dir_path = File.join(Gitlab.config.git_base_path, code)
    Dir.mkdir(namespace_dir_path) unless File.exists?(namespace_dir_path)
  end
end
