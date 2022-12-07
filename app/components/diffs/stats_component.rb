# frozen_string_literal: true

module Diffs
  class StatsComponent < BaseComponent
    attr_reader :diff_files

    def initialize(diff_files:)
      @diff_files = diff_files
      @changed ||= diff_files.size
      @added   ||= diff_files.sum(&:added_lines)
      @removed ||= diff_files.sum(&:removed_lines)
    end

    def diff_files_data
      diffs_map = @diff_files.map do |f|
        {
          href: "##{helpers.hexdigest(f.file_path)}",
          title: f.new_path,
          name: f.file_path,
          path: diff_file_path_text(f),
          icon: diff_file_changed_icon(f),
          iconColor: diff_file_changed_icon_color(f).to_s,
          added: f.added_lines,
          removed: f.removed_lines
        }
      end

      Gitlab::Json.dump(diffs_map)
    end

    def diff_file_path_text(diff_file, max: 60)
      path = diff_file.new_path

      return path unless path.size > max && max > 3

      "...#{path[-(max - 3)..]}"
    end

    private

    def diff_file_changed_icon(diff_file)
      if diff_file.deleted_file?
        "file-deletion"
      elsif diff_file.new_file?
        "file-addition"
      else
        "file-modified"
      end
    end

    def diff_file_changed_icon_color(diff_file)
      if diff_file.deleted_file?
        "danger"
      elsif diff_file.new_file?
        "success"
      end
    end
  end
end
