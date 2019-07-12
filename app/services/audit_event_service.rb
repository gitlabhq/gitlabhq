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
    log_security_event_to_file
    log_security_event_to_database
  end

  private

  def base_payload
    {
      author_id: @author.id,
      entity_id: @entity.id,
      entity_type: @entity.class.name
    }
  end

  def file_logger
    @file_logger ||= Gitlab::AuditJsonLogger.build
  end

  def formatted_details
    @details.merge(@details.slice(:from, :to).transform_values(&:to_s))
  end

  def log_security_event_to_file
    file_logger.info(base_payload.merge(formatted_details))
  end

  def log_security_event_to_database
    SecurityEvent.create(base_payload.merge(details: @details))
  end
end
