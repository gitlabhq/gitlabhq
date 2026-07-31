# frozen_string_literal: true

module Blobs
  # Renders a range of lines from a repository blob as a syntax-highlighted,
  # embeddable snippet card.
  class EmbeddedBlobComponent < ViewComponent::Base
    include SafeFormatHelper

    # @param blob [BlobPresenter] a presenter for the target blob
    # @param project [Project] the blob's project
    # @param sha [String] the immutable commit SHA the permalink pins
    # @param from [Integer] first line of the window (1-based)
    # @param to [Integer] last line of the window
    # @param cross_project [Boolean] whether the embed points at a different
    #   project than the surrounding document (in which case the title is
    #   qualified with the project's full path)
    def initialize(blob:, project:, sha:, from:, to:, cross_project: false)
      @blob = blob
      @project = project
      @sha = sha
      @from = from
      @to = to
      @cross_project = cross_project
    end

    private

    attr_reader :blob, :project, :sha, :from, :to, :cross_project

    def title_text
      cross_project ? File.join(project.full_path, blob.path) : blob.path
    end

    def range_text
      if from == to
        safe_format(_('Line %{line}'), line: from)
      else
        safe_format(_('Lines %{from} to %{to}'), from: from, to: to)
      end
    end

    def range_anchor
      from == to ? "L#{from}" : "L#{from}-#{to}"
    end

    def permalink(fragment)
      Gitlab::Routing.url_helpers.project_blob_url(project, [sha, blob.path].join('/'), anchor: fragment)
    end

    def highlighted_lines
      lines = blob.highlight(to: to, suppress_line_ids: true).lines[(from - 1)..] || []

      # Rouge output is sanitised HTML; slicing drops the html_safe flag.
      lines.join.html_safe # rubocop:disable Rails/OutputSafety -- syntax-highlighted, escaped output from Gitlab::Highlight
    end
  end
end
