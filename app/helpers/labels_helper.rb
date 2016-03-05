module LabelsHelper
  include ActionView::Helpers::TagHelper

  # Link to a Label
  #
  # label   - Label object to link to
  # project - Project object which will be used as the context for the label's
  #           link. If omitted, defaults to `@project`, or the label's own
  #           project.
  # type    - The type of item the link will point to (:issue or
  #           :merge_request). If omitted, defaults to :issue.
  # block   - An optional block that will be passed to `link_to`, forming the
  #           body of the link element. If omitted, defaults to
  #           `render_colored_label`.
  #
  # Examples:
  #
  #   # Allow the generated link to use the label's own project
  #   link_to_label(label)
  #
  #   # Force the generated link to use @project
  #   @project = Project.first
  #   link_to_label(label)
  #
  #   # Force the generated link to use a provided project
  #   link_to_label(label, project: Project.last)
  #
  #   # Force the generated link to point to merge requests instead of issues
  #   link_to_label(label, type: :merge_request)
  #
  #   # Customize link body with a block
  #   link_to_label(label) { "My Custom Label Text" }
  #
  # Returns a String
  def link_to_label(label, project: nil, type: :issue, &block)
    project ||= @project || label.project
    link = send("namespace_project_#{type.to_s.pluralize}_path",
                project.namespace,
                project,
                label_name: label.name)

    if block_given?
      link_to link, &block
    else
      link_to render_colored_label(label), link
    end
  end

  def project_label_names
    @project.labels.pluck(:title)
  end

  def render_colored_label(label, label_suffix = '')
    label_color = label.color || Label::DEFAULT_COLOR
    text_color = text_color_for_bg(label_color)

    # Intentionally not using content_tag here so that this method can be called
    # by LabelReferenceFilter
    span = %(<span class="label color-label") +
      %(style="background-color: #{label_color}; color: #{text_color}">) +
      %(#{escape_once(label.name)}#{label_suffix}</span>)

    span.html_safe
  end

  def render_colored_cross_project_label(label)
    label_suffix = label.project.name_with_namespace
    label_suffix = " <i>in #{escape_once(label_suffix)}</i>"
    render_colored_label(label, label_suffix)
  end

  def suggested_colors
    [
      '#0033CC',
      '#428BCA',
      '#44AD8E',
      '#A8D695',
      '#5CB85C',
      '#69D100',
      '#004E00',
      '#34495E',
      '#7F8C8D',
      '#A295D6',
      '#5843AD',
      '#8E44AD',
      '#FFECDB',
      '#AD4363',
      '#D10069',
      '#CC0033',
      '#FF0000',
      '#D9534F',
      '#D1D100',
      '#F0AD4E',
      '#AD8D43'
    ]
  end

  def text_color_for_bg(bg_color)
    if bg_color.length == 4
      r, g, b = bg_color[1, 4].scan(/./).map { |v| (v * 2).hex }
    else
      r, g, b = bg_color[1, 7].scan(/.{2}/).map(&:hex)
    end

    if (r + g + b) > 500
      '#333333'
    else
      '#FFFFFF'
    end
  end

  def projects_labels_options
    labels =
      if @project
        @project.labels
      else
        Label.where(project_id: @projects)
      end

    grouped_labels = GlobalLabel.build_collection(labels)
    grouped_labels.unshift(Label::None)
    grouped_labels.unshift(Label::Any)

    options_from_collection_for_select(grouped_labels, 'name', 'title', params[:label_name])
  end

  # Required for Banzai::Filter::LabelReferenceFilter
  module_function :render_colored_label, :render_colored_cross_project_label,
                  :text_color_for_bg, :escape_once
end
