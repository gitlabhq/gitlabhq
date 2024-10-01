# frozen_string_literal: true

module Diffs
  class OverflowWarningComponent < BaseComponent
    def initialize(diffs:, diff_files:, project:, commit: nil, merge_request: nil)
      @diffs = diffs
      @diff_files = diff_files
      @project = project
      @commit = commit
      @merge_request = merge_request
    end

    def message
      html_escape(message_text) % {
        display_size: @diff_files.size,
        real_size: @diffs.real_size,
        strong_open: '<strong>'.html_safe,
        strong_close: '</strong>'.html_safe
      }
    end

    def diff_link
      text = _("Plain diff")

      if commit?
        link_button_to text, project_commit_path(@project, @commit, format: :diff), class: 'gl-mr-3'
      elsif merge_request?
        link_button_to text, merge_request_path(@merge_request, format: :diff), class: 'gl-mr-3'
      end
    end

    def patch_link
      text = _("Email patch")

      if commit?
        link_button_to text, project_commit_path(@project, @commit, format: :patch)
      elsif merge_request?
        link_button_to text, merge_request_path(@merge_request, format: :patch)
      end
    end

    private

    def commit?
      current_controller?(:commit) &&
        @commit.present?
    end

    def merge_request?
      current_controller?("projects/merge_requests/diffs") &&
        @merge_request.present? &&
        @merge_request.persisted?
    end

    def message_text
      _(
        "For a faster browsing experience, only %{strong_open}%{display_size} of %{real_size}%{strong_close} " \
          "files are shown. Download one of the files below to see all changes."
      )
    end
  end
end
