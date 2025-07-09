# frozen_string_literal: true

module RapidDiffs
  class DiffFileHeaderComponent < ViewComponent::Base
    include ButtonHelper
    include DiffHelper

    def initialize(diff_file:, additional_menu_items: [])
      @diff_file = diff_file
      @additional_menu_items = additional_menu_items
    end

    def file_title_chunks
      parts = @diff_file.file_path.split('/')
      last = parts.pop
      { path_parts: parts, filename: last }
    end

    def file_link
      helpers.project_blob_path(
        @diff_file.repository.project,
        helpers.tree_join(@diff_file.content_sha, @diff_file.new_path)
      )
    end

    def copy_path_button
      clipboard_button(
        text: @diff_file.file_path,
        gfm: "`#{@diff_file.file_path}`",
        title: _("Copy file path"),
        placement: "top",
        boundary: "viewport",
        testid: "rd-diff-file-copy-clipboard",
        class: 'rd-copy-path'
      )
    end

    def menu_items
      @additional_menu_items.sort_by { |item| item[:position] || Float::INFINITY }
    end

    def heading_id
      file_heading_id(@diff_file)
    end

    def root_label
      s_('RapidDiffs|Diff file controls')
    end

    def moved_title_label
      helpers.safe_format(
        s_('RapidDiffs|File moved from %{old} to %{new}'),
        old: @diff_file.old_path,
        new: @diff_file.new_path
      )
    end

    def stats_label
      return false if @diff_file.binary?

      added = @diff_file.added_lines
      removed = @diff_file.removed_lines
      counters = []
      counters << (ns_('RapidDiffs|Added %d line.', 'RapidDiffs|Added %d lines.', added) % added) if added > 0
      counters << (ns_('RapidDiffs|Removed %d line.', 'RapidDiffs|Removed %d lines.', removed) % removed) if removed > 0
      counters.join(' ')
    end

    def pretty_print_bytes(size)
      ActiveSupport::NumberHelper.number_to_human_size(size)
    end
  end
end
