class AuditEventPresenter < Gitlab::View::Presenter::Simple
  presents :audit_event

  def author_name
    user = audit_event.user

    return nil unless user

    link_to(user.name, user_path(user))
  end

  def target
    details[:target_details]
  end

  def ip_address
    details[:ip_address]
  end

  def details
    audit_event.details
  end

  def object
    entity = audit_event.entity

    return nil unless entity

    link_to(details[:entity_path] || entity.name, entity).html_safe
  end

  def date
    audit_event.created_at.to_s(:db)
  end

  def action
    Audit::Details.humanize(details)
  end

  private

  # The class can't include ActionView::Helpers::UrlHelper because it overwrites
  # the method url_for. In this helper, that implementation of that method
  # doesn't accept objects to resolve their route. That's why here we call the
  # native url_for to get the route of the object and then call the link_to with it
  def link_to(name, object)
    ActionController::Base.helpers.link_to(name, url_for(object))
  end
end
