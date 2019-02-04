# frozen_string_literal: true

module RssHelper
  def rss_url_options
    { format: :atom, feed_token: current_user.try(:feed_token) }
  end
end
