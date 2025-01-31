# frozen_string_literal: true

module RapidDiffs
  class DiffFileHeaderComponent < ViewComponent::Base
    include ButtonHelper

    def initialize(diff_file:)
      @diff_file = diff_file
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
  end
end
