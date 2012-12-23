module Account
  # Returns a string for use as a Gitolite user identifier
  #
  # Note that Gitolite 2.x requires the following pattern for users:
  #
  #   ^@?[0-9a-zA-Z][0-9a-zA-Z._\@+-]*$
  def identifier
    # Replace non-word chars with underscores, then make sure it starts with
    # valid chars
    email.gsub(/\W/, '_').gsub(/\A([\W\_])+/, '')
  end

  def is_admin?
    admin
  end

  def require_ssh_key?
    keys.count == 0
  end

  def can_create_project?
    projects_limit > my_own_projects.count
  end

  def can_create_group?
    is_admin?
  end

  def abilities
    @abilities ||= begin
                     abilities = Six.new
                     abilities << Ability
                     abilities
                   end
  end

  def can? action, subject
    abilities.allowed?(self, action, subject)
  end

  def last_activity_project
    projects.first
  end

  def first_name
    name.split.first unless name.blank?
  end

  def cared_merge_requests
    MergeRequest.where("author_id = :id or assignee_id = :id", id: self.id)
  end

  def project_ids
    projects.map(&:id)
  end

  # Remove user from all projects and
  # set blocked attribute to true
  def block
    users_projects.find_each do |membership|
      return false unless membership.destroy
    end

    self.blocked = true
    save
  end

  def projects_limit_percent
    return 100 if projects_limit.zero?
    (my_own_projects.count.to_f / projects_limit) * 100
  end

  def recent_push project_id = nil
    # Get push events not earlier than 2 hours ago
    events = recent_events.code_push.where("created_at > ?", Time.now - 2.hours)
    events = events.where(project_id: project_id) if project_id

    # Take only latest one
    events = events.recent.limit(1).first
  end

  def projects_sorted_by_activity
    projects.sorted_by_activity
  end

  def namespaces
    namespaces = []

    # Add user account namespace
    namespaces << self.namespace if self.namespace

    # Add groups you can manage
    namespaces += if admin
                    Group.all
                  else
                    groups.all
                  end
    namespaces
  end

  def several_namespaces?
    namespaces.size > 1
  end

  def namespace_id
    namespace.try :id
  end

  def authorized_groups
    @authorized_groups ||= begin
                           groups = Group.where(id: self.projects.pluck(:namespace_id)).all
                           groups = groups + self.groups
                           groups.uniq
                         end
  end

  def authorized_projects
    Project.authorized_for(self)
  end

  def my_own_projects
    Project.personal(self)
  end
end
