module LabelsHelper
  include ActionView::Helpers::TagHelper

  # Link to a Label
  #
  # label   - Label object to link to
  # subject - Project/Group object which will be used as the context for the
  #           label's link. If omitted, defaults to the label's own group/project.
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
  #   # Force the generated link to use a provided group
  #   link_to_label(label, subject: Group.last)
  #
  #   # Force the generated link to use a provided project
  #   link_to_label(label, subject: Project.last)
  #
  #   # Force the generated link to point to merge requests instead of issues
  #   link_to_label(label, type: :merge_request)
  #
  #   # Customize link body with a block
  #   link_to_label(label) { "My Custom Label Text" }
  #
  # Returns a String
  def link_to_label(label, subject: nil, type: :issue, tooltip: true, css_class: nil, &block)
    subject ||=
      case label
      when GroupLabel then label.group
      when ProjectLabel then label.project
      end

    link = label_filter_path(subject, label, type: type)

    if block_given?
      link_to link, class: css_class, &block
    else
      link_to render_colored_label(label, tooltip: tooltip), link, class: css_class
    end
  end

  def label_filter_path(subject, label, type: :issue)
    case subject
    when Group
      send("#{type.to_s.pluralize}_group_path",
                  subject,
                  label_name: [label.name])
    when Project
      send("namespace_project_#{type.to_s.pluralize}_path",
                  subject.namespace,
                  subject,
                  label_name: [label.name])
    end
  end

  def edit_label_path(label)
    case label
    when GroupLabel then edit_group_label_path(label.group, label)
    when ProjectLabel then edit_namespace_project_label_path(label.project.namespace, label.project, label)
    end
  end

  def destroy_label_path(label)
    case label
    when GroupLabel then group_label_path(label.group, label)
    when ProjectLabel then namespace_project_label_path(label.project.namespace, label.project, label)
    end
  end

  def toggle_subscription_label_path(label)
    case label
    when GroupLabel then toggle_subscription_group_label_path(label.group, label)
    when ProjectLabel then toggle_subscription_namespace_project_label_path(label.project.namespace, label.project, label)
    end
  end

  def render_colored_label(label, label_suffix = '', tooltip: true)
    label_color = label.color || Label::DEFAULT_COLOR
    text_color = text_color_for_bg(label_color)

    # Intentionally not using content_tag here so that this method can be called
    # by LabelReferenceFilter
    span = %(<span class="label color-label #{"has-tooltip" if tooltip}" ) +
      %(style="background-color: #{label_color}; color: #{text_color}" ) +
      %(title="#{escape_once(label.description)}" data-container="body">) +
      %(#{escape_once(label.name)}#{label_suffix}</span>)

    span.html_safe
  end

  def render_colored_cross_project_label(label, source_project = nil, tooltip: true)
    label_suffix = source_project ? source_project.name_with_namespace : label.project.name_with_namespace
    label_suffix = " <i>in #{escape_once(label_suffix)}</i>"
    render_colored_label(label, label_suffix, tooltip: tooltip)
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

  def labels_filter_path
    return group_labels_path(@group, :json) if @group

    project = @target_project || @project

    if project
      namespace_project_labels_path(project.namespace, project, :json)
    else
      dashboard_labels_path(:json)
    end
  end

  def label_subscription_status(label)
    label.subscribed?(current_user) ? 'subscribed' : 'unsubscribed'
  end

  def label_subscription_toggle_button_text(label)
    label.subscribed?(current_user) ? 'Unsubscribe' : 'Subscribe'
  end

  # Required for Banzai::Filter::LabelReferenceFilter
  module_function :render_colored_label, :render_colored_cross_project_label,
                  :text_color_for_bg, :escape_once
end
