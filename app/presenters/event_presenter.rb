# frozen_string_literal: true

class EventPresenter < Gitlab::View::Presenter::Delegated
  presents :event

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
