# frozen_string_literal: true

module WhatsNewHelper
  def whats_new_most_recent_release_items_count
    ReleaseHighlight.most_recent_item_count
  end

  def whats_new_storage_key
    most_recent_version = ReleaseHighlight.most_recent_version

    return unless most_recent_version

    ['display-whats-new-notification', most_recent_version].join('-')
  end
end
