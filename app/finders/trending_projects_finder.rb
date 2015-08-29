class TrendingProjectsFinder
  def execute(current_user, start_date = nil)
    start_date ||= Date.today - 1.month

    # Determine trending projects based on comments count
    # for period of time - ex. month
    trending_project_ids = Note.
      select("notes.project_id, count(notes.project_id) as pcount").
      where('notes.created_at > ?', start_date).
      group("project_id").
      reorder("pcount DESC").
      map(&:project_id)

    sql_order_ids = trending_project_ids.reverse.
      map { |project_id| "id = #{project_id}" }.join(", ")

    # Get list of projects that user allowed to see
    projects = projects_for(current_user)
    projects.where(id: trending_project_ids).reorder(sql_order_ids)
  end

  private

  def projects_for(current_user)
    ProjectsFinder.new.execute(current_user)
  end
end
