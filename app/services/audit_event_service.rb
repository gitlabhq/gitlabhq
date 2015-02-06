class AuditEventService

  def initialize(author, entity, details = {})
    @author, @entity, @details = author, entity, details
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
