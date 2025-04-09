# frozen_string_literal: true

module RapidDiffs
  class DiffsStatsEntity < Grape::Entity
    expose :diffs_stats do |diffs_resource, _|
      {
        added_lines: diffs_resource.raw_diff_files.sum(&:added_lines),
        removed_lines: diffs_resource.raw_diff_files.sum(&:removed_lines),
        diffs_count: diffs_resource.raw_diff_files.size
      }
    end

    expose :overflow, if: ->(diffs_resource, _) {
      overflow_safe?(diffs_resource.diff_files)
    } do |diffs_resource, options|
      {
        visible_count: visible_count(diffs_resource),
        email_path: options[:email_path],
        diff_path: options[:diff_path]
      }
    end

    private

    def overflow_safe?(diff_collection)
      diff_collection.collapsed_safe_lines? || diff_collection.collapsed_safe_files? ||
        diff_collection.collapsed_safe_bytes?
    end

    def visible_count(diffs_resource)
      diffs_resource.size - diffs_resource.raw_diff_files.count(&:collapsed?)
    end
  end
end
