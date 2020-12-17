# frozen_string_literal: true

class ReleaseHighlight
  CACHE_DURATION = 1.hour
  FILES_PATH = Rails.root.join('data', 'whats_new', '*.yml')
  RELEASE_VERSIONS_IN_A_YEAR = 12

  def self.for_version(version:)
    index = self.versions.index(version)

    return if index.nil?

    page = index + 1

    self.paginated(page: page)
  end

  def self.paginated(page: 1)
    key = self.cache_key("items:page-#{page}")

    Rails.cache.fetch(key, expires_in: CACHE_DURATION) do
      items = self.load_items(page: page)

      next if items.nil?

      QueryResult.new(items: items, next_page: next_page(current_page: page))
    end
  end

  def self.load_items(page:)
    index = page - 1
    file_path = file_paths[index]

    return if file_path.nil?

    file = File.read(file_path)
    items = YAML.safe_load(file, permitted_classes: [Date])

    platform = Gitlab.com? ? 'gitlab-com' : 'self-managed'

    items&.map! do |item|
      next unless item[platform]

      begin
        item.tap {|i| i['body'] = Kramdown::Document.new(i['body']).to_html }
      rescue => e
        Gitlab::ErrorTracking.track_exception(e, file_path: file_path)

        next
      end
    end

    items&.compact
  rescue Psych::Exception => e
    Gitlab::ErrorTracking.track_exception(e, file_path: file_path)

    nil
  end

  def self.file_paths
    @file_paths ||= Rails.cache.fetch(self.cache_key('file_paths'), expires_in: CACHE_DURATION) do
      Dir.glob(FILES_PATH).sort.reverse
    end
  end

  def self.cache_key(key)
    ['release_highlight', key, Gitlab.revision].join(':')
  end

  def self.next_page(current_page: 1)
    next_page = current_page + 1
    next_index = next_page - 1

    next_page if self.file_paths[next_index]
  end

  def self.most_recent_item_count
    key = self.cache_key('recent_item_count')

    Gitlab::ProcessMemoryCache.cache_backend.fetch(key, expires_in: CACHE_DURATION) do
      self.paginated&.items&.count
    end
  end

  def self.versions
    key = self.cache_key('versions')

    Gitlab::ProcessMemoryCache.cache_backend.fetch(key, expires_in: CACHE_DURATION) do
      versions = self.file_paths.first(RELEASE_VERSIONS_IN_A_YEAR).map do |path|
        /\d*\_(\d*\_\d*)\.yml$/.match(path).captures[0].gsub(/0(?=\d)/, "").tr("_", ".")
      end

      versions.uniq
    end
  end

  QueryResult = Struct.new(:items, :next_page, keyword_init: true) do
    include Enumerable

    delegate :each, to: :items
  end
end
