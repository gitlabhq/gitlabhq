class LabelsFinder < UnionFinder
  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    items = find_union(label_ids, Label)
    items = with_title(items)
    sort(items)
  end

  private

  attr_reader :current_user, :params

  def label_ids
    label_ids = []

    if project
      label_ids << project.group.labels if project.group.present?
      label_ids << project.labels
    else
      label_ids << Label.where(group_id: projects.group_ids)
      label_ids << Label.where(project_id: projects.select(:id))
    end

    label_ids
  end

  def sort(items)
    items.reorder(title: :asc, type: :desc)
  end

  def with_title(items)
    items = items.where(title: title) if title
    items
  end

  def group_id
    params[:group_id].presence
  end

  def project_id
    params[:project_id].presence
  end

  def projects_ids
    params[:project_ids].presence
  end

  def title
    params[:title].presence
  end

  def project
    return @project if defined?(@project)

    if project_id
      @project = available_projects.find(project_id) rescue nil
    else
      @project = nil
    end

    @project
  end

  def projects
    return @projects if defined?(@projects)

    @projects = available_projects
    @projects = @projects.in_namespace(group_id) if group_id
    @projects = @projects.where(id: projects_ids) if projects_ids
    @projects = @projects.reorder(nil)

    @projects
  end

  def available_projects
    @available_projects ||= ProjectsFinder.new.execute(current_user)
  end
end
