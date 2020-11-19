# frozen_string_literal: true

module WhatsNewHelper
  include Gitlab::WhatsNew

  def whats_new_most_recent_release_items_count
    Gitlab::ProcessMemoryCache.cache_backend.fetch('whats_new:release_items_count', expires_in: CACHE_DURATION) do
      whats_new_release_items&.count
    end
  end

  def whats_new_storage_key
    return unless whats_new_most_recent_version

    ['display-whats-new-notification', whats_new_most_recent_version].join('-')
  end

  private

  def whats_new_most_recent_version
    Gitlab::ProcessMemoryCache.cache_backend.fetch('whats_new:release_version', expires_in: CACHE_DURATION) do
      whats_new_release_items&.first&.[]('release')
    end
  end
end
