# frozen_string_literal: true

class AuditEventService
  # Instantiates a new service
  #
  # @param author [User] the user who authors the change
  # @param entity [Object] an instance of either Project/Group/User type. This
  #   param is also used to determine at which level the audit events are
  #   shown.
  #   - Project: events are visible at Project level
  #   - Group: events are visible at Group level
  #   - User: events are visible at Instance level
  # @param details [Hash] details to be added to audit event
  #
  # @return [AuditEventService]
  def initialize(author, entity, details = {})
    @author = author
    @entity = entity
    @details = details
  end

  # Builds the @details attribute for authentication
  #
  # This uses the @author as the target object being changed
  #
  # @return [AuditEventService]
  def for_authentication
    @details = {
      with: @details[:with],
      target_id: @author.id,
      target_type: 'User',
      target_details: @author.name
    }

    self
  end

  # Writes event to a file and creates an event record in DB
  #
  # @return [SecurityEvent] persited if saves and non-persisted if fails
  def security_event
    log_security_event_to_file
    log_security_event_to_database
  end

  # Writes event to a file
  def log_security_event_to_file
    file_logger.info(base_payload.merge(formatted_details))
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

  def log_security_event_to_database
    return if Gitlab::Database.read_only?

    SecurityEvent.create(base_payload.merge(details: @details))
  end
end

AuditEventService.prepend_if_ee('EE::AuditEventService')
