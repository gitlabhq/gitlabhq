# frozen_string_literal: true

class ReleaseHighlight
  CACHE_DURATION = 1.hour
  FILES_PATH = Rails.root.join('data', 'whats_new', '*.yml')

  def self.paginated(page: 1)
    Rails.cache.fetch(cache_key(page), expires_in: CACHE_DURATION) do
      items = self.load_items(page: page)

      next if items.nil?

      {
        items: items,
        next_page: next_page(current_page: page)
      }
    end
  end

  def self.load_items(page:)
    index = page - 1
    file_path = file_paths[index]

    return if file_path.nil?

    file = File.read(file_path)

    items = YAML.safe_load(file, permitted_classes: [Date])

    platform = Gitlab.com? ? 'gitlab-com' : 'self-managed'
    items&.select {|item| item[platform] }
  rescue Psych::Exception => e
    Gitlab::ErrorTracking.track_exception(e, file_path: file_path)

    nil
  end

  def self.file_paths
    @file_paths ||= Rails.cache.fetch('release_highlight:file_paths', expires_in: CACHE_DURATION) do
      Dir.glob(FILES_PATH).sort.reverse
    end
  end

  def self.cache_key(page)
    filename = /\d*\_\d*\_\d*/.match(self.file_paths&.first)
    "release_highlight:items:file-#{filename}:page-#{page}"
  end

  def self.next_page(current_page: 1)
    next_page = current_page + 1
    next_index = next_page - 1

    next_page if self.file_paths[next_index]
  end

  def self.most_recent_version
    Gitlab::ProcessMemoryCache.cache_backend.fetch('release_highlight:release_version', expires_in: CACHE_DURATION) do
      self.paginated&.[](:items)&.first&.[]('release')
    end
  end

  def self.most_recent_item_count
    Gitlab::ProcessMemoryCache.cache_backend.fetch('release_highlight:recent_item_count', expires_in: CACHE_DURATION) do
      self.paginated&.[](:items)&.count
    end
  end
end
