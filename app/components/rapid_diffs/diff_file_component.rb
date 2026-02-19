# frozen_string_literal: true

module RapidDiffs
  class DiffFileComponent < ViewComponent::Base
    include TreeHelper
    include DiffHelper

    renders_one :header

    def initialize(
      diff_file:,
      parallel_view: false,
      plain_view: false,
      environment: nil,
      extra_file_data: {},
      extra_options: {}
    )
      @diff_file = plain_view ? diff_file : diff_file.rendered || diff_file
      @parallel_view = parallel_view
      @environment = environment
      @extra_file_data = extra_file_data
      @extra_options = extra_options
    end

    def id
      @diff_file.file_hash
    end

    def file_data
      project = @diff_file.repository.project
      params = tree_join(@diff_file.content_sha, @diff_file.file_path)
      data = {
        viewer: viewer_component.viewer_name,
        diff_lines_path: project_blob_diff_lines_path(project, params),
        old_path: @diff_file.old_path,
        new_path: @diff_file.new_path
      }
      data.merge(@extra_file_data)
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
      render RapidDiffs::DiffFileHeaderComponent.new(
        diff_file: @diff_file,
        environment: @environment
      )
    end

    # enables virtual rendering through content-visibility: auto, significantly boosts client performance
    def virtual?
      !viewer_component_instance.virtual_rendering_params.nil? && !@diff_file.rendered?
    end

    def virtual_rendering_styles
      viewer_component_instance.virtual_rendering_params.each_with_object([]) do |(key, value), acc|
        acc << "--virtual-#{key.to_s.dasherize}: #{value}"
      end.join(';')
    end

    def heading_id
      file_heading_id(@diff_file)
    end

    def classes
      [
        'rd-diff-file-component',
        ('rd-diff-file-component-linked' if @diff_file.linked),
        ('rd-diff-file-component-conflict' if @diff_file.respond_to?(:conflict) && @diff_file.conflict),
        *Array.wrap(@extra_options[:class])
      ].compact
    end

    def root_options
      {
        id: id,
        class: classes,
        data: {
          testid: 'rd-diff-file',
          file_data: file_data.to_json
        }
      }.deep_merge(@extra_options.except(:class))
    end
  end
end
