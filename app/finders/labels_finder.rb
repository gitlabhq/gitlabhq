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
    label_ids << Label.where(group_id: projects.joins(:namespace).where(namespaces: { type: 'Group' }).select(:namespace_id)).select(:id)
    label_ids << Label.where(project_id: projects.select(:id)).select(:id)
  end

  def sort(items)
    items.reorder(title: :asc, type: :desc)
  end

  def with_title(items)
    items = items.where(title: title) if title.present?
    items
  end

  def group_id
    params[:group_id].presence
  end

  def project_id
    params[:project_id].presence
  end

  def title
    params[:title].presence
  end

  def projects
    return @projects if defined?(@projects)

    @projects = ProjectsFinder.new.execute(current_user)
    @projects = @projects.joins(:namespace).where(namespaces: { id: group_id, type: 'Group' }) if group_id
    @projects = @projects.where(id: project_id) if project_id
    @projects = @projects.reorder(nil)

    @projects
  end
end
