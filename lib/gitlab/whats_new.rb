# frozen_string_literal: true

module Gitlab
  module WhatsNew
    CACHE_DURATION = 1.hour
    WHATS_NEW_FILES_PATH = Rails.root.join('data', 'whats_new', '*.yml')

    private

    def whats_new_release_items(page: 1)
      Rails.cache.fetch(whats_new_items_cache_key(page), expires_in: CACHE_DURATION) do
        index = page - 1
        file_path = whats_new_file_paths[index]

        next if file_path.nil?

        file = File.read(file_path)

        items = YAML.safe_load(file, permitted_classes: [Date])

        items if items.is_a?(Array)
      end
    rescue => e
      Gitlab::ErrorTracking.track_exception(e, page: page)

      nil
    end

    def whats_new_file_paths
      @whats_new_file_paths ||= Rails.cache.fetch('whats_new:file_paths', expires_in: CACHE_DURATION) do
        Dir.glob(WHATS_NEW_FILES_PATH).sort.reverse
      end
    end

    def whats_new_items_cache_key(page)
      filename = /\d*\_\d*\_\d*/.match(whats_new_file_paths&.first)
      "whats_new:release_items:file-#{filename}:page-#{page}"
    end
  end
end
