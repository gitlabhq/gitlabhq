module LabelsHelper
  extend self
  include ActionView::Helpers::TagHelper

  def show_label_issuables_link?(label, issuables_type, current_user: nil, project: nil)
    return true if label.is_a?(GroupLabel)
    return true unless project

    project.feature_available?(issuables_type, current_user)
  end

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
  #   # Allow the generated link to use the label's own subject
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
    link = label_filter_path(subject || label.subject, label, type: type)

    if block_given?
      link_to link, class: css_class, &block
    else
      link_to render_colored_label(label, tooltip: tooltip), link, class: css_class
    end
  end

  def label_filter_path(subject, label, type: :issue)
    case subject
    when Group
      send("#{type.to_s.pluralize}_group_path", # rubocop:disable GitlabSecurity/PublicSend
                  subject,
                  label_name: [label.name])
    when Project
      send("namespace_project_#{type.to_s.pluralize}_path", # rubocop:disable GitlabSecurity/PublicSend
                  subject.namespace,
                  subject,
                  label_name: [label.name])
    end
  end

  def edit_label_path(label)
    case label
    when GroupLabel then edit_group_label_path(label.group, label)
    when ProjectLabel then edit_project_label_path(label.project, label)
    end
  end

  def destroy_label_path(label)
    case label
    when GroupLabel then group_label_path(label.group, label)
    when ProjectLabel then project_label_path(label.project, label)
    end
  end

  def render_colored_label(label, label_suffix = '', tooltip: true)
    text_color = text_color_for_bg(label.color)

    # Intentionally not using content_tag here so that this method can be called
    # by LabelReferenceFilter
    span = %(<span class="badge color-label #{"has-tooltip" if tooltip}" ) +
      %(style="background-color: #{label.color}; color: #{text_color}" ) +
      %(title="#{escape_once(label.description)}" data-container="body">) +
      %(#{escape_once(label.name)}#{label_suffix}</span>)

    span.html_safe
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

  def labels_filter_path(only_group_labels = false, include_ancestor_groups: true, include_descendant_groups: false)
    project = @target_project || @project

    options = {}
    options[:include_ancestor_groups] = include_ancestor_groups if include_ancestor_groups
    options[:include_descendant_groups] = include_descendant_groups if include_descendant_groups

    if project
      project_labels_path(project, :json, options)
    elsif @group
      options[:only_group_labels] = only_group_labels if only_group_labels
      group_labels_path(@group, :json, options)
    else
      dashboard_labels_path(:json)
    end
  end

  def can_subscribe_to_label_in_different_levels?(label)
    defined?(@project) && label.is_a?(GroupLabel)
  end

  def label_subscription_status(label, project)
    return 'group-level' if label.subscribed?(current_user)
    return 'project-level' if label.subscribed?(current_user, project)

    'unsubscribed'
  end

  def toggle_subscription_label_path(label, project)
    return toggle_subscription_group_label_path(label.group, label) unless project

    case label_subscription_status(label, project)
    when 'group-level' then toggle_subscription_group_label_path(label.group, label)
    when 'project-level' then toggle_subscription_project_label_path(project, label)
    when 'unsubscribed' then toggle_subscription_project_label_path(project, label)
    end
  end

  def label_subscription_toggle_button_text(label, project = nil)
    label.subscribed?(current_user, project) ? 'Unsubscribe' : 'Subscribe'
  end

  def label_deletion_confirm_text(label)
    case label
    when GroupLabel then 'Remove this label? This will affect all projects within the group. Are you sure?'
    when ProjectLabel then 'Remove this label? Are you sure?'
    end
  end

  def create_label_title(subject)
    case subject
    when Group
      _('Create group label')
    when Project
      _('Create project label')
    else
      _('Create new label')
    end
  end

  def manage_labels_title(subject)
    case subject
    when Group
      _('Manage group labels')
    when Project
      _('Manage project labels')
    else
      _('Manage labels')
    end
  end

  def view_labels_title(subject)
    case subject
    when Group
      _('View group labels')
    when Project
      _('View project labels')
    else
      _('View labels')
    end
  end

  # Required for Banzai::Filter::LabelReferenceFilter
  module_function :render_colored_label, :text_color_for_bg, :escape_once
end
