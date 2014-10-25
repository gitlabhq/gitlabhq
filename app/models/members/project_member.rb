# == Schema Information
#
# Table name: members
#
#  id                 :integer          not null, primary key
#  access_level       :integer          not null
#  source_id          :integer          not null
#  source_type        :string(255)      not null
#  user_id            :integer          not null
#  notification_level :integer          not null
#  type               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#

class ProjectMember < Member
  SOURCE_TYPE = 'Project'

  include Gitlab::ShellAdapter

  belongs_to :project, class_name: 'Project', foreign_key: 'source_id'


  # Make sure project member points only to project as it source
  default_value_for :source_type, SOURCE_TYPE
  default_value_for :notification_level, Notification::N_GLOBAL
  validates_format_of :source_type, with: /\AProject\z/
  default_scope { where(source_type: SOURCE_TYPE) }

  after_create :post_create_hook
  after_update :post_update_hook
  after_destroy :post_destroy_hook

  scope :in_project, ->(project) { where(source_id: project.id) }
  scope :in_projects, ->(projects) { where(source_id: projects.pluck(:id)) }
  scope :with_user, ->(user) { where(user_id: user.id) }

  class << self

    # Add users to project teams with passed access option
    #
    # access can be an integer representing a access code
    # or symbol like :master representing role
    #
    # Ex.
    #   add_users_into_projects(
    #     project_ids,
    #     user_ids,
    #     ProjectMember::MASTER
    #   )
    #
    #   add_users_into_projects(
    #     project_ids,
    #     user_ids,
    #     :master
    #   )
    #
    def add_users_into_projects(project_ids, user_ids, access)
      access_level = if roles_hash.has_key?(access)
                       roles_hash[access]
                     elsif roles_hash.values.include?(access.to_i)
                       access
                     else
                       raise "Non valid access"
                     end

      ProjectMember.transaction do
        project_ids.each do |project_id|
          user_ids.each do |user_id|
            member = ProjectMember.new(access_level: access_level, user_id: user_id)
            member.source_id = project_id
            member.save
          end
        end
      end

      true
    rescue
      false
    end

    def truncate_teams(project_ids)
      ProjectMember.transaction do
        members = ProjectMember.where(source_id: project_ids)
        members.each do |member|
          member.destroy
        end
      end

      true
    rescue
      false
    end

    def truncate_team(project)
      truncate_teams [project.id]
    end

    def roles_hash
      Gitlab::Access.sym_options
    end

    def access_roles
      Gitlab::Access.options
    end
  end

  def access_field
    access_level
  end

  def owner?
    project.owner == user
  end

  def post_create_hook
    Event.create(
      project_id: self.project.id,
      action: Event::JOINED,
      author_id: self.user.id
    )

    notification_service.new_team_member(self) unless owner?
    system_hook_service.execute_hooks_for(self, :create)
  end

  def post_update_hook
    notification_service.update_team_member(self) if self.access_level_changed?
  end

  def post_destroy_hook
    Event.create(
      project_id: self.project.id,
      action: Event::LEFT,
      author_id: self.user.id
    )

    system_hook_service.execute_hooks_for(self, :destroy)
  end

  def notification_service
    NotificationService.new
  end

  def system_hook_service
    SystemHooksService.new
  end

  def project
    source
  end
end
