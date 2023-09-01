# frozen_string_literal: true

# Detect links matching the following formats:
# Zoom Start links: https://zoom.us/s/<meeting-id>
# Zoom Join links: https://zoom.us/j/<meeting-id>
# Personal Zoom links: https://zoom.us/my/<meeting-id>
# Vanity Zoom links: https://gitlab.zoom.us/j/<meeting-id> (also /s and /my)

module Gitlab
  class ZoomLinkExtractor
    ZOOM_REGEXP = %r{https://(?:[\w-]+\.)?zoom\.us/(?:s|j|my)/\S+}

    def initialize(text)
      @text = text.to_s
    end

    def links
      @text.scan(ZOOM_REGEXP)
    end

    def match?
      ZOOM_REGEXP.match?(@text)
    end
  end
end
