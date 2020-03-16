# frozen_string_literal: true

module ClientsidePreviewCSP
  extend ActiveSupport::Concern

  included do
    content_security_policy do |p|
      next if p.directives.blank?
      next unless Gitlab::CurrentSettings.web_ide_clientside_preview_enabled?

      default_frame_src = p.directives['frame-src'] || p.directives['default-src']
      frame_src_values = Array.wrap(default_frame_src) | [Gitlab::CurrentSettings.web_ide_clientside_preview_bundler_url].compact

      p.frame_src(*frame_src_values)
    end
  end
end
