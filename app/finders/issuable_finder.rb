# IssuableFinder
#
# Used to filter Issues and MergeRequests collections by set of params
#
# Arguments:
#   klass - actual class like Issue or MergeRequest
#   current_user - which user use
#   params:
#     scope: 'created-by-me' or 'assigned-to-me' or 'all'
#     state: 'open' or 'closed' or 'all'
#     group_id: integer
#     project_id: integer
#     milestone_title: string
#     assignee_id: integer
#     search: string
#     label_name: string
#     sort: string
#
require_relative 'projects_finder'

class IssuableFinder
  NONE = '0'

  attr_accessor :current_user, :params

  def initialize(current_user, params)
    @current_user = current_user
    @params = params
  end

  def execute
    items = init_collection
    items = by_scope(items)
    items = by_state(items)
    items = by_group(items)
    items = by_project(items)
    items = by_search(items)
    items = by_milestone(items)
    items = by_assignee(items)
    items = by_author(items)
    items = by_label(items)
    sort(items)
  end

  def group
    return @group if defined?(@group)

    @group =
      if params[:group_id].present?
        Group.find(params[:group_id])
      else
        nil
      end
  end

  def project?
    params[:project_id].present?
  end

  def project
    return @project if defined?(@project)

    if project?
      @project = Project.find(params[:project_id])
      
      unless Ability.abilities.allowed?(current_user, :read_project, @project)
        @project = nil
      end 
    else
      @project = nil
    end

    @project
  end

  def projects
    return @projects if defined?(@projects)

    if project?
      project
    elsif current_user && params[:authorized_only].presence && !current_user_related?
      current_user.authorized_projects
    else
      ProjectsFinder.new.execute(current_user)
    end
  end

  def search
    params[:search].presence
  end

  def milestones?
    params[:milestone_title].present?
  end

  def filter_by_no_milestone?
    milestones? && params[:milestone_title] == Milestone::None.title
  end

  def milestones
    return @milestones if defined?(@milestones)

    @milestones =
      if milestones?
        scope = Milestone.where(project_id: projects)

        scope.where(title: params[:milestone_title])
      else
        nil
      end
  end

  def labels?
    params[:label_name].present?
  end

  def filter_by_no_label?
    labels? && params[:label_name] == Label::None.title
  end

  def assignee?
    params[:assignee_id].present?
  end

  def assignee
    return @assignee if defined?(@assignee)

    @assignee =
      if assignee? && params[:assignee_id] != NONE
        User.find(params[:assignee_id])
      else
        nil
      end
  end

  def author?
    params[:author_id].present?
  end

  def author
    return @author if defined?(@author)

    @author =
      if author? && params[:author_id] != NONE
        User.find(params[:author_id])
      else
        nil
      end
  end

  private

  def init_collection
    klass.all
  end

  def by_scope(items)
    case params[:scope]
    when 'created-by-me', 'authored' then
      items.where(author_id: current_user.id)
    when 'all' then
      items
    when 'assigned-to-me' then
      items.where(assignee_id: current_user.id)
    else
      raise 'You must specify default scope'
    end
  end

  def by_state(items)
    case params[:state]
    when 'closed'
      items.closed
    when 'merged'
      items.respond_to?(:merged) ? items.merged : items.closed
    when 'all'
      items
    when 'opened'
      items.opened
    else
      raise 'You must specify default state'
    end
  end

  def by_group(items)
    items = items.of_group(group) if group

    items
  end

  def by_project(items)
    items =
      if projects
        items.of_projects(projects).references(:project)
      else
        items.none
      end

    items
  end

  def by_search(items)
    items = items.search(search) if search

    items
  end

  def sort(items)
    items.sort(params[:sort])
  end

  def by_assignee(items)
    if assignee?
      items = items.where(assignee_id: assignee.try(:id))
    end

    items
  end

  def by_author(items)
    if author?
      items = items.where(author_id: author.try(:id))
    end

    items
  end

  def by_milestone(items)
    if milestones?
      if filter_by_no_milestone?
        items = items.where(milestone_id: [-1, nil])
      else
        items = items.joins(:milestone).where(milestones: { title: params[:milestone_title] })

        if projects
          items = items.where(milestones: { project_id: projects })
        end
      end
    end

    items
  end

  def by_label(items)
    if labels?
      if filter_by_no_label?
        items = items.
          joins("LEFT OUTER JOIN label_links ON label_links.target_type = '#{klass.name}' AND label_links.target_id = #{klass.table_name}.id").
          where(label_links: { id: nil })
      else
        label_names = params[:label_name].split(",")

        items = items.joins(:labels).where(labels: { title: label_names })

        if projects
          items = items.where(labels: { project_id: projects })
        end
      end
    end

    items
  end

  def current_user_related?
    params[:scope] == 'created-by-me' || params[:scope] == 'authored' || params[:scope] == 'assigned-to-me'
  end
end
