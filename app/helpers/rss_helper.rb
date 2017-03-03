module RssHelper
  def rss_url_options
    { format: :atom, private_token: current_user.try(:private_token) }
  end
end
