# frozen_string_literal: true

module WhatsNewHelper
  EMPTY_JSON = ''.to_json

  def whats_new_most_recent_release_items_count
    items = parsed_most_recent_release_items

    return unless items.is_a?(Array)

    items.count
  end

  def whats_new_storage_key
    items = parsed_most_recent_release_items

    return unless items.is_a?(Array)

    release = items.first.try(:[], 'release')

    ['display-whats-new-notification', release].compact.join('-')
  end

  def whats_new_most_recent_release_items
    YAML.load_file(most_recent_release_file_path).to_json

  rescue => e
    Gitlab::ErrorTracking.track_exception(e, yaml_file_path: most_recent_release_file_path)

    EMPTY_JSON
  end

  private

  def parsed_most_recent_release_items
    Gitlab::Json.parse(whats_new_most_recent_release_items)
  end

  def most_recent_release_file_path
    Dir.glob(files_path).max
  end

  def files_path
    Rails.root.join('data', 'whats_new', '*.yml')
  end
end
