class LabelsFinder < UnionFinder
  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute(skip_authorization: false)
    @skip_authorization = skip_authorization
    items = find_union(label_ids, Label)
    items = with_title(items)
    sort(items)
  end

  private

  attr_reader :current_user, :params, :skip_authorization

  def label_ids
    label_ids = []

    if project
      label_ids << project.group.labels if project.group.present?
      label_ids << project.labels
    else
      label_ids << Label.where(group_id: projects.group_ids.uniq)
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

  def group_id
    params[:group_id].presence
  end

  def project_id
    params[:project_id].presence
  end

  def projects_ids
    params[:project_ids]
  end

  def title
    params[:title] || params[:name]
  end

  def project
    return @project if defined?(@project)

    if project_id
      @project = find_project
    else
      @project = nil
    end

    @project
  end

  def find_project
    if skip_authorization
      Project.find_by(id: project_id)
    else
      available_projects.find_by(id: project_id)
    end
  end

  def projects
    return @projects if defined?(@projects)

    @projects = skip_authorization ? Project.all : available_projects
    @projects = @projects.in_namespace(group_id) if group_id
    @projects = @projects.where(id: projects_ids) if projects_ids
    @projects = @projects.reorder(nil)

    @projects
  end

  def available_projects
    @available_projects ||= ProjectsFinder.new.execute(current_user)
  end
end
