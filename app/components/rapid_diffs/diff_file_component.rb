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
      # return Viewers::CollapsedComponent if collapsed?
      # return Viewers::NotDiffableComponent unless diffable?

      is_text = @diff_file.text_diff?
      return Viewers::Text::ParallelViewComponent if is_text && @parallel_view
      return Viewers::Text::InlineViewComponent if is_text
      return Viewers::NoPreviewComponent if @diff_file.content_changed?

      # return Viewers::AddedComponent if new_file?
      # return Viewers::DeletedComponent if deleted_file?
      # return Viewers::RenamedComponent if renamed_file?
      # return Viewers::ModeChangedComponent if mode_changed?

      Viewers::NoPreviewComponent
    end
  end
end
