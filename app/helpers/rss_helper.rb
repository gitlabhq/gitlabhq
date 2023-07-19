# frozen_string_literal: true

module RssHelper
  def rss_url_options
    { format: :atom, feed_token: generate_feed_token(:atom) }
  end
end
