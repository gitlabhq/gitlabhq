# frozen_string_literal: true

Gitlab.ee do
  if Gitlab::Geo.connected? && Gitlab::Geo.primary?
    Gitlab::Geo.current_node&.update_clone_url!
  end
rescue StandardError => e
  warn "WARNING: Unable to check/update clone_url_prefix for Geo: #{e}"
end
