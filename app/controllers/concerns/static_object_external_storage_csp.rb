# frozen_string_literal: true

module StaticObjectExternalStorageCSP
  extend ActiveSupport::Concern

  included do
    content_security_policy do |p|
      next if p.directives.blank?
      next unless Gitlab::CurrentSettings.static_objects_external_storage_enabled?

      default_connect_src = p.directives['connect-src'] || p.directives['default-src']
      connect_src_values =
        Array.wrap(default_connect_src) | [Gitlab::CurrentSettings.static_objects_external_storage_url]
      p.connect_src(*connect_src_values)
    end
  end
end
