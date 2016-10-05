# Finder for retrieving public trending projects in a given time range.
class TrendingProjectsFinder
  # current_user - The currently logged in User, if any.
  # last_months - The number of months to limit the trending data to.
  def execute(months_limit = 1)
    Rails.cache.fetch(cache_key_for(months_limit), expires_in: 1.day) do
      Project.public_only.trending(months_limit.months.ago)
    end
  end

  private

  def cache_key_for(months)
    "trending_projects/#{months}"
  end
end
