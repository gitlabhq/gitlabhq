class
AuditEventPresenter < Gitlab::View::Presenter::Simple
  presents :audit_event

  def author_name
    audit_event.author_name || '(removed)'
  end

  def target
    audit_event.details[:target_details]
  end

  def ip_address
    audit_event.details[:ip_address]
  end

  def object
    audit_event.details[:entity_path]
  end

  def date
    audit_event.created_at.to_s(:db)
  end

  def action
    Audit::Details.humanize(audit_event.details)
  end
end
