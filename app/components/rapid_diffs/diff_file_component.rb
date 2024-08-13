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
        blob_diff_path: project_blob_diff_path(project, params)
      }
    end

    def web_component_context
      viewer_name = viewer.partial_name
      if viewer_name == 'text'
        viewer_name = @parallel_view ? 'text_parallel' : 'text_inline'
      end

      {
        viewer: viewer_name
      }
    end

    def viewer
      @diff_file.view_component_viewer
    end
  end
end
