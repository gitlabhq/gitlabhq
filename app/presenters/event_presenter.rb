# frozen_string_literal: true

class EventPresenter < Gitlab::View::Presenter::Delegated
  presents :event

  def initialize(subject, **attributes)
    super

    @visible_to_user_cache = ActiveSupport::Cache::MemoryStore.new
  end

  # Caching `visible_to_user?` method in the presenter beause it might be called multiple times.
  def visible_to_user?(user = nil)
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
    else
      target.noteable_type.titleize
    end.downcase
  end
end
