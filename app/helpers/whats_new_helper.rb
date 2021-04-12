# frozen_string_literal: true

module WhatsNewHelper
  def whats_new_most_recent_release_items_count
    ReleaseHighlight.most_recent_item_count
  end

  def whats_new_version_digest
    ReleaseHighlight.most_recent_version_digest
  end
end
