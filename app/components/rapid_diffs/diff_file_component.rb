# frozen_string_literal: true

module RapidDiffs
  class DiffFileComponent < ViewComponent::Base
    include TreeHelper
    include DiffHelper

    renders_one :header

    def initialize(diff_file:, parallel_view: false)
      @diff_file = diff_file
      @parallel_view = parallel_view
    end

    def id
      @diff_file.file_hash
    end

    def file_data
      project = @diff_file.repository.project
      params = tree_join(@diff_file.content_sha, @diff_file.file_path)
      {
        viewer: viewer_component.viewer_name,
        diff_lines_path: project_blob_diff_lines_path(project, params)
      }
    end

    def viewer_component
      return Viewers::NoPreviewComponent if empty_diff?

      if @diff_file.diffable_text?
        return Viewers::Text::ParallelViewComponent if @parallel_view

        return Viewers::Text::InlineViewComponent
      end

      return Viewers::ImageViewComponent if @diff_file.image_diff?

      Viewers::NoPreviewComponent
    end

    def empty_diff?
      @diff_file.collapsed? || !@diff_file.modified_file?
    end

    def default_header
      render RapidDiffs::DiffFileHeaderComponent.new(diff_file: @diff_file)
    end

    def total_rows
      return 0 unless !empty_diff? && @diff_file.diffable_text?

      count = 0
      @diff_file.viewer_hunks.each do |hunk|
        count += hunk.header.expand_directions.count if hunk.header
        count += @parallel_view ? hunk.parallel_lines.count : hunk.lines.count
      end
      count
    end

    # enables virtual rendering through content-visibility: auto, significantly boosts client performance
    def virtual?
      total_rows > 0
    end

    def heading_id
      file_heading_id(@diff_file)
    end
  end
end
