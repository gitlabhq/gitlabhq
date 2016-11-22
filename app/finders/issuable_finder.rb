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

  def initialize(current_user, params = {})
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
    items = by_due_date(items)
    sort(items)
  end

  def find(*params)
    execute.find(*params)
  end

  def find_by(*params)
    execute.find_by(*params)
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

    project = Project.find(params[:project_id])
    project = nil unless Ability.allowed?(current_user, :"read_#{klass.to_ability_name}", project)

    @project = project
  end

  def projects
    return @projects if defined?(@projects)
    return @projects = project if project?

    projects =
      if current_user && params[:authorized_only].presence && !current_user_related?
        current_user.authorized_projects
      elsif group
        GroupProjectsFinder.new(group).execute(current_user)
      else
        ProjectsFinder.new.execute(current_user)
      end

    @projects = projects.with_feature_available_for_user(klass, current_user).reorder(nil)
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
        Milestone.none
      end
  end

  def labels?
    params[:label_name].present?
  end

  def filter_by_no_label?
    labels? && params[:label_name].include?(Label::None.title)
  end

  def labels
    return @labels if defined?(@labels)

    @labels =
      if labels? && !filter_by_no_label?
        LabelsFinder.new(current_user, project_ids: projects, title: label_names).execute(skip_authorization: true)
      else
        Label.none
      end
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
    when 'created-by-me', 'authored'
      items.where(author_id: current_user.id)
    when 'assigned-to-me'
      items.where(assignee_id: current_user.id)
    else
      items
    end
  end

  def by_state(items)
    params[:state] ||= 'all'

    if items.respond_to?(params[:state])
      items.public_send(params[:state])
    else
      items
    end
  end

  def by_group(items)
    # Selection by group is already covered by `by_project` and `projects`
    items
  end

  def by_project(items)
    items =
      if project?
        items.of_projects(projects).references_project
      elsif projects
        items.merge(projects.reorder(nil)).join_project
      else
        items.none
      end

    items
  end

  def by_search(items)
    if search
      items =
        if search =~ iid_pattern
          items.where(iid: $~[:iid])
        else
          items.full_search(search)
        end
    end

    items
  end

  def sort(items)
    # Ensure we always have an explicit sort order (instead of inheriting
    # multiple orders when combining ActiveRecord::Relation objects).
    params[:sort] ? items.sort(params[:sort], excluded_labels: label_names) : items.reorder(id: :desc)
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

  def filter_by_upcoming_milestone?
    params[:milestone_title] == Milestone::Upcoming.name
  end

  def by_milestone(items)
    if milestones?
      if filter_by_no_milestone?
        items = items.left_joins_milestones.where(milestone_id: [-1, nil])
      elsif filter_by_upcoming_milestone?
        upcoming_ids = Milestone.upcoming_ids_by_projects(projects)
        items = items.left_joins_milestones.where(milestone_id: upcoming_ids)
      else
        items = items.with_milestone(params[:milestone_title])

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
        items = items.without_label
      else
        items = items.with_label(label_names, params[:sort])

        if projects
          label_ids = LabelsFinder.new(current_user, project_ids: projects).execute(skip_authorization: true).select(:id)
          items = items.where(labels: { id: label_ids })
        end
      end
    end

    items
  end

  def by_due_date(items)
    if due_date?
      if filter_by_no_due_date?
        items = items.without_due_date
      elsif filter_by_overdue?
        items = items.due_before(Date.today)
      elsif filter_by_due_this_week?
        items = items.due_between(Date.today.beginning_of_week, Date.today.end_of_week)
      elsif filter_by_due_this_month?
        items = items.due_between(Date.today.beginning_of_month, Date.today.end_of_month)
      end
    end

    items
  end

  def filter_by_no_due_date?
    due_date? && params[:due_date] == Issue::NoDueDate.name
  end

  def filter_by_overdue?
    due_date? && params[:due_date] == Issue::Overdue.name
  end

  def filter_by_due_this_week?
    due_date? && params[:due_date] == Issue::DueThisWeek.name
  end

  def filter_by_due_this_month?
    due_date? && params[:due_date] == Issue::DueThisMonth.name
  end

  def due_date?
    params[:due_date].present? && klass.column_names.include?('due_date')
  end

  def label_names
    if labels?
      params[:label_name].is_a?(String) ? params[:label_name].split(',') : params[:label_name]
    else
      []
    end
  end

  def current_user_related?
    params[:scope] == 'created-by-me' || params[:scope] == 'authored' || params[:scope] == 'assigned-to-me'
  end
end
