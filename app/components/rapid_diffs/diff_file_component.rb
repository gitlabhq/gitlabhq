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
        diff_lines_path: project_blob_diff_lines_path(project, params),
        old_path: @diff_file.old_path,
        new_path: @diff_file.new_path
      }
    end

    def viewer_component
      return Viewers::NoPreviewComponent if @diff_file.no_preview?

      if @diff_file.diffable_text?
        return Viewers::Text::ParallelViewComponent if @parallel_view

        return Viewers::Text::InlineViewComponent
      end

      return Viewers::ImageViewComponent if @diff_file.image_diff?

      Viewers::NoPreviewComponent
    end

    def viewer_component_instance
      viewer_component.new(diff_file: @diff_file)
    end

    def default_header
      render RapidDiffs::DiffFileHeaderComponent.new(diff_file: @diff_file)
    end

    # enables virtual rendering through content-visibility: auto, significantly boosts client performance
    def virtual?
      viewer_component_instance.virtual_rendering_params != nil
    end

    def virtual_rendering_styles
      viewer_component_instance.virtual_rendering_params.each_with_object([]) do |(key, value), acc|
        acc << "--virtual-#{key.to_s.dasherize}: #{value}"
      end.join(';')
    end

    def heading_id
      file_heading_id(@diff_file)
    end
  end
end
