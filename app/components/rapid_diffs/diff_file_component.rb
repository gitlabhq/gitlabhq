# frozen_string_literal: true

module RapidDiffs
  class DiffFileComponent < ViewComponent::Base
    include TreeHelper

    def initialize(diff_file:, parallel_view: false)
      @diff_file = diff_file
      @parallel_view = parallel_view
    end

    def id
      @diff_file.file_identifier_hash
    end

    def server_data
      project = @diff_file.repository.project
      params = tree_join(@diff_file.content_sha, @diff_file.file_path)
      {
        viewer: viewer_component.viewer_name,
        blob_diff_path: project_blob_diff_path(project, params)
      }
    end

    def viewer_component
      return Viewers::NoPreviewComponent if @diff_file.collapsed? || !@diff_file.modified_file?

      if @diff_file.diffable_text?
        return Viewers::Text::ParallelViewComponent if @parallel_view

        return Viewers::Text::InlineViewComponent
      end

      Viewers::NoPreviewComponent
    end
  end
end
