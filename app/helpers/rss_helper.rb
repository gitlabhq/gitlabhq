module RssHelper
  def rss_url_options
    { format: :atom, rss_token: current_user.try(:rss_token) }
  end
end
