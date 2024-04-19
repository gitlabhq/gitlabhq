# frozen_string_literal: true

module LabelsHelper
  extend self

  def show_label_issuables_link?(label, issuables_type, current_user: nil)
    return true unless label.project_label?

    label.project.feature_available?(issuables_type, current_user)
  end

  # Link to a Label
  #
  # label   - LabelPresenter object to link to
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
  def link_to_label(label, type: :issue, tooltip: true, css_class: nil, &block)
    link = label.filter_path(type: type)

    if block
      link_to link, class: css_class, &block
    else
      render_label(label, link: link, tooltip: tooltip)
    end
  end

  def render_label(label, link: nil, tooltip: true, dataset: nil, tooltip_shows_title: false)
    html = render_colored_label(label)

    if link
      title = label_tooltip_title(label, tooltip_shows_title: tooltip_shows_title) if tooltip
      html = render_label_link(html, link: link, title: title, dataset: dataset)
    end

    wrap_label_html(html, label: label)
  end

  def render_colored_label(label, suffix: '')
    render_label_text(
      label.name,
      suffix: suffix,
      css_class: "gl-label-text #{label.text_color_class}",
      bg_color: label.color
    )
  end

  # We need the `label` argument here for EE
  def wrap_label_html(label_html, label:)
    wrapper_classes = %w[gl-label]

    %(<span class="#{wrapper_classes.join(' ')}">#{label_html}</span>).html_safe
  end

  def label_tooltip_title(label, tooltip_shows_title: false)
    Sanitize.clean(tooltip_shows_title ? label.title : label.description)
  end

  def suggested_colors
    {
      '#cc338b' => s_('SuggestedColors|Magenta-pink'),
      '#dc143c' => s_('SuggestedColors|Crimson'),
      '#c21e56' => s_('SuggestedColors|Rose red'),
      '#cd5b45' => s_('SuggestedColors|Dark coral'),
      '#ed9121' => s_('SuggestedColors|Carrot orange'),
      '#eee600' => s_('SuggestedColors|Titanium yellow'),
      '#009966' => s_('SuggestedColors|Green-cyan'),
      '#8fbc8f' => s_('SuggestedColors|Dark sea green'),
      '#6699cc' => s_('SuggestedColors|Blue-gray'),
      '#e6e6fa' => s_('SuggestedColors|Lavender'),
      '#9400d3' => s_('SuggestedColors|Dark violet'),
      '#330066' => s_('SuggestedColors|Deep violet'),
      '#36454f' => s_('SuggestedColors|Charcoal grey'),
      '#808080' => s_('SuggestedColors|Gray')
    }
  end

  def render_suggested_colors
    colors_html = suggested_colors.map do |color_hex_value, color_name|
      link_to('', '#', class: "has-tooltip", style: "background-color: #{color_hex_value}", data: { color: color_hex_value }, title: color_name)
    end

    content_tag(:div, class: 'suggest-colors') do
      colors_html.join.html_safe
    end
  end

  def text_color_for_bg(bg_color)
    ::Gitlab::Color.of(bg_color).contrast
  end

  def labels_filter_path_with_defaults(only_group_labels: false, include_ancestor_groups: true, include_descendant_groups: false)
    options = {}
    options[:include_ancestor_groups] = include_ancestor_groups if include_ancestor_groups
    options[:include_descendant_groups] = include_descendant_groups if include_descendant_groups
    options[:only_group_labels] = only_group_labels if only_group_labels && @group
    options[:format] = :json

    labels_filter_path(options)
  end

  def labels_filter_path(options = {})
    project = @target_project || @project
    format = options.delete(:format)

    if project
      project_labels_path(project, format, options)
    elsif @group
      group_labels_path(@group, format, options)
    else
      dashboard_labels_path(format, options)
    end
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
    label.subscribed?(current_user, project) ? _('Unsubscribe') : _('Subscribe')
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

  def label_status_tooltip(label, status)
    type = label.project_label? ? 'project' : 'group'
    level = status.unsubscribed? ? type : status.sub('-level', '')
    action = status.unsubscribed? ? 'Subscribe' : 'Unsubscribe'

    "#{action} at #{level} level"
  end

  def presented_labels_sorted_by_title(labels, subject)
    labels.sort_by(&:title).map { |label| label.present(issuable_subject: subject) }
  end

  def label_dropdown_data(project, opts = {})
    {
      toggle: "dropdown",
      field_name: opts[:field_name] || "label_name[]",
      show_no: "true",
      show_any: "true",
      project_id: project&.try(:id),
      namespace_path: project&.try(:namespace)&.try(:full_path),
      project_path: project&.try(:path)
    }.merge(opts)
  end

  def labels_function_introduction
    _('Labels can be applied to issues and merge requests. Group labels are available for any project within the group.')
  end

  def show_labels_full_path?(project, group)
    project || group&.subgroup?
  end

  def label_lock_on_merge_help_text
    _('IMPORTANT: Use this setting only for VERY strict auditing purposes. ' \
      'When turned on, nobody will be able to remove the label from any merge requests after they are merged. ' \
      'In addition, nobody will be able to turn off this setting or delete this label.')
  end

  private

  def render_label_link(label_html, link:, title:, dataset:)
    classes = %w[gl-link gl-label-link]
    dataset ||= {}

    if title.present?
      classes << 'has-tooltip'
      dataset.merge!(html: true, title: title)
    end

    link_to(label_html, link, class: classes.join(' '), data: dataset)
  end

  def render_label_text(name, suffix: '', css_class: nil, bg_color: nil)
    <<~HTML.chomp.html_safe
      <span
        class="#{css_class}"
        data-container="body"
        data-html="true"
        #{"style=\"background-color: #{h bg_color}\"" if bg_color}
      >#{ERB::Util.html_escape_once(name)}#{suffix}</span>
    HTML
  end
end

LabelsHelper.prepend_mod_with('LabelsHelper')
