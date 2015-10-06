class TrendingProjectsFinder
  def execute(current_user, start_date = 1.month.ago)
    projects_for(current_user).trending(start_date)
  end

  private

  def projects_for(current_user)
    ProjectsFinder.new.execute(current_user)
  end
end
