# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#  type        :string(255)
#  description :string(255)      default(""), not null
#  avatar      :string(255)
#

class Namespace < ActiveRecord::Base
  include Gitlab::ShellAdapter

  has_many :projects, dependent: :destroy
  belongs_to :owner, class_name: "User"

  validates :owner, presence: true, unless: ->(n) { n.type == "Group" }
  validates :name, presence: true, uniqueness: true,
            length: { within: 0..255 },
            format: { with: Gitlab::Regex.name_regex,
                      message: Gitlab::Regex.name_regex_message }
  validates :description, length: { within: 0..255 }
  validates :path, uniqueness: { case_sensitive: false }, presence: true, length: { within: 1..255 },
            exclusion: { in: Gitlab::Blacklist.path },
            format: { with: Gitlab::Regex.path_regex,
                      message: Gitlab::Regex.path_regex_message }

  delegate :name, to: :owner, allow_nil: true, prefix: true

  after_create :ensure_dir_exist
  after_update :move_dir, if: :path_changed?
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
    gitlab_shell.add_namespace(path)
  end

  def rm_dir
    gitlab_shell.rm_namespace(path)
  end

  def move_dir
    if gitlab_shell.mv_namespace(path_was, path)
      # If repositories moved successfully we need to remove old satellites
      # and send update instructions to users.
      # However we cannot allow rollback since we moved namespace dir
      # So we basically we mute exceptions in next actions
      begin
        gitlab_shell.rm_satellites(path_was)
        send_update_instructions
      rescue
        # Returning false does not rollback after_* transaction but gives
        # us information about failing some of tasks
        false
      end
    else
      # if we cannot move namespace directory we should rollback
      # db changes in order to prevent out of sync between db and fs
      raise Exception.new('namespace directory cannot be moved')
    end
  end

  def send_update_instructions
    projects.each(&:send_move_instructions)
  end

  def kind
    type == 'Group' ? 'group' : 'user'
  end
end
