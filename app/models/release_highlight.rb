# frozen_string_literal: true

class ReleaseHighlight
  CACHE_DURATION = 1.hour

  FREE_PACKAGE = 'Free'
  PREMIUM_PACKAGE = 'Premium'
  ULTIMATE_PACKAGE = 'Ultimate'

  def self.paginated(page: 1)
    result = self.paginated_query(page: page)
    result = self.paginated_query(page: result.next_page) while next_page?(result)
    result
  end

  def self.paginated_query(page:)
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

    items&.map! do |item|
      next unless include_item?(item)

      begin
        item.tap { |i| i['description'] = Banzai.render(i['description'], { project: nil }) }
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, file_path: file_path)

        next
      end
    end

    items&.compact
  rescue Psych::Exception => e
    Gitlab::ErrorTracking.track_exception(e, file_path: file_path)

    []
  end

  def self.whats_new_path
    Rails.root.join('data/whats_new/*.yml')
  end

  def self.file_paths
    @file_paths ||= self.relative_file_paths.map { |path| path.prepend(Rails.root.to_s) }
  end

  def self.relative_file_paths
    Rails.cache.fetch(self.cache_key('file_paths'), expires_in: CACHE_DURATION) do
      Dir.glob(whats_new_path).reverse.map { |path| path.delete_prefix(Rails.root.to_s) }
    end
  end

  def self.cache_key(key)
    variant = Gitlab::CurrentSettings.current_application_settings.whats_new_variant
    ['release_highlight', variant, key, Gitlab.revision].join(':')
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

  def self.most_recent_version_digest
    key = self.cache_key('most_recent_version_digest')

    Gitlab::ProcessMemoryCache.cache_backend.fetch(key, expires_in: CACHE_DURATION) do
      version = self.paginated&.items&.first&.[]('release')&.to_s

      next if version.nil?

      Digest::SHA256.hexdigest(version)
    end
  end

  QueryResult = Struct.new(:items, :next_page, keyword_init: true) do
    include Enumerable

    delegate :each, to: :items
  end

  def self.current_package
    return FREE_PACKAGE unless defined?(License)

    case License.current&.plan&.downcase
    when License::PREMIUM_PLAN
      PREMIUM_PACKAGE
    when License::ULTIMATE_PLAN
      ULTIMATE_PACKAGE
    else
      FREE_PACKAGE
    end
  end

  def self.include_item?(item)
    platform = Gitlab.com? ? 'gitlab-com' : 'self-managed'

    return false unless item[platform]

    return true unless Gitlab::CurrentSettings.current_application_settings.whats_new_variant_current_tier?

    item['available_in']&.include?(current_package)
  end

  def self.next_page?(result)
    return false unless result

    # if all items for the current page doesn't belong to the current tier
    # or failed to parse current YAML, loading next page
    result.items == [] && result.next_page.present?
  end
end

ReleaseHighlight.prepend_mod
