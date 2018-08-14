# frozen_string_literal: true

class AuditEventService
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

  def security_event
    SecurityEvent.create(
      author_id: @author.id,
      entity_id: @entity.id,
      entity_type: @entity.class.name,
      details: @details
    )
  end
end
