class LabelsFinder < UnionFinder
  prepend FinderWithCrossProjectAccess
  include FinderMethods
  include Gitlab::Utils::StrongMemoize

  requires_cross_project_access unless: -> { project? }

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute(skip_authorization: false)
    @skip_authorization = skip_authorization
    items = find_union(label_ids, Label) || Label.none
    items = with_title(items)
    sort(items)
  end

  private

  attr_reader :current_user, :params, :skip_authorization

  def label_ids
    label_ids = []

    if project?
      if project
        if project.group.present?
          labels_table = Label.arel_table

          label_ids << Label.where(
            labels_table[:type].eq('GroupLabel').and(labels_table[:group_id].eq(project.group.id)).or(
              labels_table[:type].eq('ProjectLabel').and(labels_table[:project_id].eq(project.id))
            )
          )
        else
          label_ids << project.labels
        end
      end
    elsif only_group_labels?
      label_ids << Label.where(group_id: group_ids)
    else
      label_ids << Label.where(group_id: projects.group_ids)
      label_ids << Label.where(project_id: projects.select(:id))
    end

    label_ids
  end

  def sort(items)
    items.reorder(title: :asc)
  end

  def with_title(items)
    return items if title.nil?
    return items.none if title.blank?

    items.where(title: title)
  end

  def group_ids
    strong_memoize(:group_ids) do
      groups_user_can_read_labels(groups_to_include).map(&:id)
    end
  end

  def groups_to_include
    group = Group.find(params[:group_id])
    groups = [group]

    groups += group.ancestors if params[:include_ancestor_groups].present?
    groups += group.descendants if params[:include_descendant_groups].present?

    groups
  end

  def group?
    params[:group_id].present?
  end

  def project?
    params[:project_id].present?
  end

  def projects?
    params[:project_ids]
  end

  def only_group_labels?
    params[:only_group_labels]
  end

  def title
    params[:title] || params[:name]
  end

  def project
    return @project if defined?(@project)

    if project?
      @project = Project.find(params[:project_id])
      @project = nil unless authorized_to_read_labels?(@project)
    else
      @project = nil
    end

    @project
  end

  def projects
    return @projects if defined?(@projects)

    @projects = if skip_authorization
                  Project.all
                else
                  ProjectsFinder.new(params: { non_archived: true }, current_user: current_user).execute
                end

    @projects = @projects.in_namespace(params[:group_id]) if group?
    @projects = @projects.where(id: params[:project_ids]) if projects?
    @projects = @projects.reorder(nil)

    @projects
  end

  def authorized_to_read_labels?(label_parent)
    return true if skip_authorization

    Ability.allowed?(current_user, :read_label, label_parent)
  end

  def groups_user_can_read_labels(groups)
    DeclarativePolicy.user_scope do
      groups.select { |group| authorized_to_read_labels?(group) }
    end
  end
end
