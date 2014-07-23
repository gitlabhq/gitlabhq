class TrendingProjectsFinder
  def execute(current_user, start_date = nil)
    start_date ||= Date.today - 1.month

    projects = projects_for(current_user)

    # Determine trending projects based on comments count
    # for period of time - ex. month
    projects.joins(:notes).where('notes.created_at > ?', start_date).
      select("projects.*, count(notes.id) as ncount").
      group("projects.id").order("ncount DESC")
  end

  private

  def projects_for(current_user)
    ProjectsFinder.new.execute(current_user)
  end
end
