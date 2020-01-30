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
      [event.project.namespace.becomes(Namespace), event.project, event.target]
    else
      ''
    end
  end
end
