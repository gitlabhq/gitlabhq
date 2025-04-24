# frozen_string_literal: true

module RapidDiffs
  class DiffFileHeaderComponent < ViewComponent::Base
    include ButtonHelper

    def initialize(diff_file:, additional_menu_items: [])
      @diff_file = diff_file
      @additional_menu_items = additional_menu_items
    end

    def copy_path_button
      clipboard_button(
        text: @diff_file.file_path,
        gfm: "`#{@diff_file.file_path}`",
        title: _("Copy file path"),
        placement: "top",
        boundary: "viewport",
        testid: "rd-diff-file-copy-clipboard"
      )
    end

    def menu_items
      base_items = [
        {
          text: helpers.safe_format(
            _('View file @ %{commitSha}'),
            commitSha: Commit.truncate_sha(@diff_file.content_sha)
          ),
          href: helpers.project_blob_path(
            @diff_file.repository.project,
            helpers.tree_join(@diff_file.content_sha, @diff_file.new_path)
          ),
          position: 0
        }
      ]

      [*base_items, *@additional_menu_items].sort_by { |item| item[:position] || Float::INFINITY }
    end
  end
end
