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
    label_ids << Label.where(group_id: projects.where.not(group: nil).select(:namespace_id)).select(:id)
    label_ids << Label.where(project_id: projects.select(:id)).select(:id)
  end

  def with_title(items)
    items = items.where(title: title) if title.present?
    items
  end

  def sort(items)
    items.reorder(title: :asc)
  end

  def project_id
    params[:project_id].presence
  end

  def title
    params[:title].presence
  end

  def projects
    return @projects if defined?(@projects)

    if project_id
      @projects = ProjectsFinder.new.execute(current_user)
                                    .where(id: project_id)
                                    .reorder(nil)
    else
      @projects = Project.none
    end

    @projects
  end
end
