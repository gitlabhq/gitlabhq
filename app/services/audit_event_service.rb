class AuditEventService
  prepend EE::AuditEventService

  def initialize(author, entity, details = {})
    @author, @entity, @details = author, entity, details
  end

  def for_authentication
    @details = {
      with: @details[:with],
      target_id: @author.id,
      target_type: 'User',
      target_details: @author.name
    }

    self
  end

  def for_changes
    @details =
      {
        change: @details[:as] || @details[:column],
        from: @details[:from],
        to: @details[:to],
        author_name: @author.name,
        target_id: @entity.id,
        target_type: @entity.class,
        target_details: @entity.name
      }
    self
  end


  def security_event
    SecurityEvent.create(
      author_id: @author.id,
      entity_id: @entity.id,
      entity_type: @entity.class.name,
      details: @details
    )
  end
end
