class LabelsFinder < UnionFinder
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
        label_ids << project.group.labels if project.group.present?
        label_ids << project.labels
      end
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

  def group?
    params[:group_id].present?
  end

  def project?
    params[:project_id].present?
  end

  def projects?
    params[:project_ids].present?
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

    @projects = skip_authorization ? Project.all : ProjectsFinder.new.execute(current_user)
    @projects = @projects.in_namespace(params[:group_id]) if group?
    @projects = @projects.where(id: params[:project_ids]) if projects?
    @projects = @projects.reorder(nil)

    @projects
  end

  def authorized_to_read_labels?(project)
    return true if skip_authorization

    Ability.allowed?(current_user, :read_label, project)
  end
end
