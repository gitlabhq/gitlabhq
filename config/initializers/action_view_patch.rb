# frozen_string_literal: true

# Even though `ActionView::Helpers::AssetTagHelper.preload_links_header`
# is set to false, `preload_link_tag` sends the Link header if the total
# header size to send is under 8K. However, this causes HTTP responses
# to fail in NGINX if the default `proxy_buffer_size` is set too low.
#
# Ironically because `app/views/layouts/_loading_hints.html.haml` is a
# cached partial, `preload_link_tag` generates the HTML, but only
# actually sends the `Link` header once a minute when the cache expires.
# This suggests that the `Link` header isn't really helping much, and it
# causes more trouble than it's worth.
#
# Rails 7.1 lowered the `preload_link_tag` limit to 1000 bytes in
# https://github.com/rails/rails/pull/48405, but that may not be
# sufficient.
#
# https://github.com/rails/rails/issues/51436 proposes to disable the
# sending of the Link header entirely. This patch does this by turning
# send_preload_links_header into a NOP.
#
# We can probably drop this patch for Rails 7.1 and up, but we might
# want to wait for https://github.com/rails/rails/pull/51441 or some
# mechanism that can disable the `Link` header.
if Gem::Version.new(ActionView.version) >= Gem::Version.new('7.2')
  raise 'New version of ActionView detected. This patch can likely be removed.'
end

require "action_view/helpers/asset_tag_helper"

module ActionView
  module Helpers
    module AssetTagHelper
      def send_preload_links_header(preload_links, max_header_size: MAX_HEADER_SIZE); end
    end
  end
end
