# IssuableFinder
#
# Used to filter Issues and MergeRequests collections by set of params
#
# Arguments:
#   klass - actual class like Issue or MergeRequest
#   current_user - which user use
#   params:
#     scope: 'created-by-me' or 'assigned-to-me' or 'all'
#     state: 'opened' or 'closed' or 'all'
#     group_id: integer
#     project_id: integer
#     milestone_title: string
#     author_id: integer
#     assignee_id: integer
#     search: string
#     label_name: string
#     sort: string
#     non_archived: boolean
#     iids: integer[]
#     my_reaction_emoji: string
#     created_after: datetime
#     created_before: datetime
#     updated_after: datetime
#     updated_before: datetime
#
class IssuableFinder
  prepend FinderWithCrossProjectAccess
  include FinderMethods
  include CreatedAtFilter

  requires_cross_project_access unless: -> { project? }

  NONE = '0'.freeze

  attr_accessor :current_user, :params

  def self.scalar_params
    @scalar_params ||= %i[
      assignee_id
      assignee_username
      author_id
      author_username
      authorized_only
      group_id
      iids
      label_name
      milestone_title
      my_reaction_emoji
      non_archived
      project_id
      scope
      search
      sort
      state
      include_subgroups
    ]
  end

  def self.array_params
    @array_params ||= { label_name: [], iids: [], assignee_username: [] }
  end

  def self.valid_params
    @valid_params ||= scalar_params + [array_params]
  end

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    items = init_collection
    items = filter_items(items)

    # Filtering by project HAS TO be the last because we use the project IDs yielded by the issuable query thus far
    items = by_project(items)

    sort(items)
  end

  def filter_items(items)
    items = by_scope(items)
    items = by_created_at(items)
    items = by_updated_at(items)
    items = by_state(items)
    items = by_group(items)
    items = by_search(items)
    items = by_assignee(items)
    items = by_author(items)
    items = by_non_archived(items)
    items = by_iids(items)
    items = by_milestone(items)
    items = by_label(items)
    by_my_reaction_emoji(items)
  end

  def row_count
    Gitlab::IssuablesCountForState.new(self).for_state_or_opened(params[:state])
  end

  # We often get counts for each state by running a query per state, and
  # counting those results. This is typically slower than running one query
  # (even if that query is slower than any of the individual state queries) and
  # grouping and counting within that query.
  #
  def count_by_state
    count_params = params.merge(state: nil, sort: nil)
    labels_count = label_names.any? ? label_names.count : 1
    finder = self.class.new(current_user, count_params)
    counts = Hash.new(0)

    # Searching by label includes a GROUP BY in the query, but ours will be last
    # because it is added last. Searching by multiple labels also includes a row
    # per issuable, so we have to count those in Ruby - which is bad, but still
    # better than performing multiple queries.
    #
    finder.execute.reorder(nil).group(:state).count.each do |key, value|
      counts[Array(key).last.to_sym] += value / labels_count
    end

    counts[:all] = counts.values.sum

    counts
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

  def projects(items = nil)
    return @projects = project if project?

    projects =
      if current_user && params[:authorized_only].presence && !current_user_related?
        current_user.authorized_projects
      elsif group
        finder_options = { include_subgroups: params[:include_subgroups], only_owned: true }
        GroupProjectsFinder.new(group: group, current_user: current_user, options: finder_options).execute
      else
        opts = { current_user: current_user }
        opts[:project_ids_relation] = item_project_ids(items) if items

        ProjectsFinder.new(opts).execute
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
        if project?
          group_id = project.group&.id
          project_id = project.id
        end

        group_id = group.id if group

        search_params =
          { title: params[:milestone_title], project_ids: project_id, group_ids: group_id }

        MilestonesFinder.new(search_params).execute
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

  def assignee_id?
    params[:assignee_id].present? && params[:assignee_id] != NONE
  end

  def assignee_username?
    params[:assignee_username].present? && params[:assignee_username] != NONE
  end

  def no_assignee?
    # Assignee_id takes precedence over assignee_username
    params[:assignee_id] == NONE || params[:assignee_username] == NONE
  end

  def assignee
    return @assignee if defined?(@assignee)

    @assignee =
      if assignee_id?
        User.find_by(id: params[:assignee_id])
      elsif assignee_username?
        User.find_by(username: params[:assignee_username])
      else
        nil
      end
  end

  def author_id?
    params[:author_id].present? && params[:author_id] != NONE
  end

  def author_username?
    params[:author_username].present? && params[:author_username] != NONE
  end

  def no_author?
    # author_id takes precedence over author_username
    params[:author_id] == NONE || params[:author_username] == NONE
  end

  def author
    return @author if defined?(@author)

    @author =
      if author_id?
        User.find_by(id: params[:author_id])
      elsif author_username?
        User.find_by(username: params[:author_username])
      else
        nil
      end
  end

  private

  def init_collection
    klass.all
  end

  def by_scope(items)
    return items.none if current_user_related? && !current_user

    case params[:scope]
    when 'created-by-me', 'authored'
      items.where(author_id: current_user.id)
    when 'assigned-to-me'
      items.assigned_to(current_user)
    else
      items
    end
  end

  def by_updated_at(items)
    items = items.updated_after(params[:updated_after]) if params[:updated_after].present?
    items = items.updated_before(params[:updated_before]) if params[:updated_before].present?

    items
  end

  def by_state(items)
    case params[:state].to_s
    when 'closed'
      items.closed
    when 'merged'
      items.respond_to?(:merged) ? items.merged : items.closed
    when 'opened'
      items.opened
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
    search ? items.full_search(search) : items
  end

  def by_iids(items)
    params[:iids].present? ? items.where(iid: params[:iids]) : items
  end

  def sort(items)
    # Ensure we always have an explicit sort order (instead of inheriting
    # multiple orders when combining ActiveRecord::Relation objects).
    params[:sort] ? items.sort_by_attribute(params[:sort], excluded_labels: label_names) : items.reorder(id: :desc)
  end

  def by_assignee(items)
    if assignee
      items = items.where(assignee_id: assignee.id)
    elsif no_assignee?
      items = items.where(assignee_id: nil)
    elsif assignee_id? || assignee_username? # assignee not found
      items = items.none
    end

    items
  end

  def by_author(items)
    if author
      items = items.where(author_id: author.id)
    elsif no_author?
      items = items.where(author_id: nil)
    elsif author_id? || author_username? # author not found
      items = items.none
    end

    items
  end

  def filter_by_upcoming_milestone?
    params[:milestone_title] == Milestone::Upcoming.name
  end

  def filter_by_started_milestone?
    params[:milestone_title] == Milestone::Started.name
  end

  def by_milestone(items)
    if milestones?
      if filter_by_no_milestone?
        items = items.left_joins_milestones.where(milestone_id: [-1, nil])
      elsif filter_by_upcoming_milestone?
        upcoming_ids = Milestone.upcoming_ids_by_projects(projects(items))
        items = items.left_joins_milestones.where(milestone_id: upcoming_ids)
      elsif filter_by_started_milestone?
        items = items.left_joins_milestones.where('milestones.start_date <= NOW()')
      else
        items = items.with_milestone(params[:milestone_title])
      end
    end

    items
  end

  def by_label(items)
    return items unless labels?

    items =
      if filter_by_no_label?
        items.without_label
      else
        items.with_label(label_names, params[:sort])
      end

    items
  end

  def by_my_reaction_emoji(items)
    if params[:my_reaction_emoji].present? && current_user
      items = items.awarded(current_user, params[:my_reaction_emoji])
    end

    items
  end

  def label_names
    if labels?
      params[:label_name].is_a?(String) ? params[:label_name].split(',') : params[:label_name]
    else
      []
    end
  end

  def by_non_archived(items)
    params[:non_archived].present? ? items.non_archived : items
  end

  def current_user_related?
    params[:scope] == 'created-by-me' || params[:scope] == 'authored' || params[:scope] == 'assigned-to-me'
  end
end
