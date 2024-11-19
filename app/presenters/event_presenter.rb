# frozen_string_literal: true

class EventPresenter < Gitlab::View::Presenter::Delegated
  presents ::Event, as: :event

  def initialize(event, **attributes)
    super

    @visible_to_user_cache = ActiveSupport::Cache::MemoryStore.new
  end

  # Caching `visible_to_user?` method in the presenter because it might be called multiple times.
  delegator_override :visible_to_user?
  def visible_to_user?(user = nil)
    return super(user) unless user

    @visible_to_user_cache.fetch(user&.id) { super(user) }
  end

  # implement cache here
  def resource_parent_name
    resource_parent&.full_name || ''
  end

  def target_link_options
    case resource_parent
    when Group
      [event.group, event.target]
    when Project
      [event.project, event.target]
    else
      ''
    end
  end

  def target_type_name
    if design?
      'Design'
    elsif wiki_page?
      'Wiki Page'
    elsif issue? || work_item?
      target.issue_type
    elsif target_type.present?
      target_type.titleize
    else
      "Project"
    end.downcase
  end

  def note_target_type_name
    return unless note?

    if design_note?
      'Design'
    elsif wiki_page_note?
      'Wiki Page'
    elsif target.for_issue? || target.for_work_item?
      target.noteable.issue_type
    else
      target.noteable_type.titleize
    end.downcase
  end

  def push_activity_description
    return unless push_action?

    if batch_push?
      "#{action_name} #{ref_count} #{ref_type.pluralize(ref_count)}"
    else
      "#{action_name} #{ref_type}"
    end
  end

  def batch_push?
    push_action? && ref_count.to_i > 0
  end

  def linked_to_reference?
    return false unless push_action?
    return false if event.project.nil?

    if tag?
      project.repository.tag_exists?(ref_name)
    else
      project.repository.branch_exists?(ref_name)
    end
  end
end
