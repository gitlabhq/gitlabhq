# frozen_string_literal: true

module EventsHelper
  ICON_NAMES_BY_EVENT_TYPE = {
    'pushed to' => 'commit',
    'pushed new' => 'commit',
    'updated' => 'commit',
    'created' => 'status_open',
    'opened' => 'status_open',
    'closed' => 'status_closed',
    'accepted' => 'fork',
    'commented on' => 'comment',
    'deleted' => 'remove',
    'destroyed' => 'remove',
    'imported' => 'import',
    'joined' => 'users'
  }.freeze

  def link_to_author(event, self_added: false)
    author = event.author

    if author
      name = self_added ? 'You' : author.name
      link_to name, user_path(author.username), title: name
    else
      escape_once(event.author_name)
    end
  end

  def event_action_name(event)
    target = event.note_target_type_name || event.target_type_name

    [event.action_name, target].join(" ")
  end

  def event_filter_link(key, text, tooltip)
    key = key.to_s
    active = 'active' if @event_filter.active?(key)
    link_opts = {
      class: "event-filter-link",
      id:    "#{key}_event_filter",
      title: tooltip
    }

    content_tag :li, class: active do
      link_to request.path, link_opts do
        content_tag(:span, ' ' + text)
      end
    end
  end

  def event_filter_visible(feature_key)
    return designs_visible? if feature_key == :designs
    return true unless @project

    @project.feature_available?(feature_key, current_user)
  end

  def designs_visible?
    if @project
      design_activity_enabled?(@project)
    elsif @group
      design_activity_enabled?(@group)
    elsif @projects
      @projects.with_namespace.include_project_feature.any? { |p| design_activity_enabled?(p) }
    else
      true
    end
  end

  def design_activity_enabled?(project)
    Ability.allowed?(current_user, :read_design_activity, project)
  end

  def comments_visible?
    event_filter_visible(:repository) ||
      event_filter_visible(:merge_requests) ||
      event_filter_visible(:issues)
  end

  def event_preposition(event)
    if event.wiki_page?
      'in the wiki for'
    elsif event.milestone?
      'in'
    elsif event.push_action? || event.commented_action? || event.target
      'at'
    end
  end

  def event_feed_title(event)
    words = []
    words << event.author_name
    words << event_action_name(event)

    if event.push_action?
      words << event.ref_type
      words << event.ref_name
      words << "at"
    elsif event.commented_action?
      words << event.note_target_reference
      words << "at"
    elsif event.milestone?
      words << "##{event.target_iid}" if event.target_iid
      words << "in"
    elsif event.design?
      words << event.design.to_reference
      words << "in"
    elsif event.wiki_page?
      words << event.target_title
      words << "in"
    elsif event.target
      prefix =
        if event.merge_request?
          MergeRequest.reference_prefix
        else
          Issue.reference_prefix
        end

      words << "#{prefix}#{event.target_iid}:" if event.target_iid
      words << event.target.title if event.target.respond_to?(:title)
      words << "at"
    end

    words << event.resource_parent_name

    words.join(" ")
  end

  def event_feed_url(event)
    if event.issue?
      project_issue_url(event.project,
                                  event.issue)
    elsif event.merge_request?
      project_merge_request_url(event.project, event.merge_request)
    elsif event.commit_note?
      project_commit_url(event.project,
                                   event.note_target)
    elsif event.note?
      if event.note_target
        event_note_target_url(event)
      end
    elsif event.push_action?
      push_event_feed_url(event)
    elsif event.created_project_action?
      project_url(event.project)
    end
  end

  def push_event_feed_url(event)
    if event.push_with_commits? && event.md_ref?
      if event.commits_count > 1
        project_compare_url(event.project,
                                      from: event.commit_from, to:
                                      event.commit_to)
      else
        project_commit_url(event.project,
                                     id: event.commit_to)
      end
    elsif event.ref_name
      project_commits_url(event.project,
                                    event.ref_name)
    end
  end

  def event_feed_summary(event)
    if event.issue?
      render "events/event_issue", issue: event.issue
    elsif event.push_action?
      render "events/event_push", event: event
    elsif event.merge_request?
      render "events/event_merge_request", merge_request: event.merge_request
    elsif event.note?
      render "events/event_note", note: event.note
    end
  end

  def event_note_target_url(event)
    if event.commit_note?
      project_commit_url(event.project, event.note_target, anchor: dom_id(event.target))
    elsif event.snippet_note?
      gitlab_snippet_url(event.note_target, anchor: dom_id(event.target))
    elsif event.issue_note?
      project_issue_url(event.project, id: event.note_target, anchor: dom_id(event.target))
    elsif event.merge_request_note?
      project_merge_request_url(event.project, id: event.note_target, anchor: dom_id(event.target))
    elsif event.design_note?
      design_url(event.note_target, anchor: dom_id(event.note))
    else
      polymorphic_url([event.project, event.note_target],
                        anchor: dom_id(event.target))
    end
  end

  def event_wiki_title_html(event)
    capture do
      concat content_tag(:span, _('wiki page'), class: "event-target-type gl-mr-2")
      concat link_to(event.target_title, event_wiki_page_target_url(event),
                     title: event.target_title,
                     class: 'has-tooltip event-target-link gl-mr-2')
    end
  end

  def event_design_title_html(event)
    capture do
      concat content_tag(:span, _('design'), class: "event-target-type gl-mr-2")
      concat link_to(event.design.reference_link_text, design_url(event.design),
                     title: event.target_title,
                     class: 'has-tooltip event-design event-target-link gl-mr-2')
    end
  end

  def event_wiki_page_target_url(event)
    project_wiki_url(event.project, event.target&.canonical_slug || Wiki::HOMEPAGE)
  end

  def event_note_title_html(event)
    if event.note_target
      capture do
        concat content_tag(:span, event.note_target_type_name, class: "event-target-type gl-mr-2")
        concat link_to(event.note_target_reference, event_note_target_url(event), title: event.target_title, class: 'has-tooltip event-target-link gl-mr-2')
      end
    else
      content_tag(:strong, '(deleted)')
    end
  end

  def event_commit_title(message)
    message ||= ''
    (message.split("\n").first || "").truncate(70)
  rescue StandardError
    "--broken encoding"
  end

  def icon_for_event(note, size: 24)
    icon_name = ICON_NAMES_BY_EVENT_TYPE[note]
    sprite_icon(icon_name, size: size) if icon_name
  end

  DESIGN_ICONS = {
    'created' => 'upload',
    'updated' => 'pencil',
    'destroyed' => ICON_NAMES_BY_EVENT_TYPE['destroyed']
  }.freeze

  def design_event_icon(action, size: 24)
    icon_name = DESIGN_ICONS[action]
    sprite_icon(icon_name, size: size) if icon_name
  end

  def icon_for_profile_event(event)
    if current_path?('users#show')
      content_tag :div, class: "system-note-image #{event.action_name.parameterize}-icon" do
        icon_for_event(event.action_name)
      end
    else
      content_tag :div, class: 'system-note-image user-avatar' do
        author_avatar(event, size: 32)
      end
    end
  end

  def inline_event_icon(event)
    unless current_path?('users#show')
      content_tag :span, class: "system-note-image-inline d-none d-sm-flex gl-mr-2 #{event.action_name.parameterize}-icon align-self-center" do
        next design_event_icon(event.action, size: 14) if event.design?

        icon_for_event(event.action_name, size: 14)
      end
    end
  end

  def event_user_info(event)
    content_tag(:div, class: "event-user-info") do
      concat content_tag(:span, link_to_author(event), class: "author-name")
      concat "&nbsp;".html_safe
      concat content_tag(:span, event.author.to_reference, class: "username")
    end
  end

  private

  def design_url(design, opts = {})
    designs_project_issue_url(
      design.project,
      design.issue,
      opts.merge(vueroute: design.filename)
    )
  end
end

EventsHelper.prepend_mod_with('EventsHelper')
