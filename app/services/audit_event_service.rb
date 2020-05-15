# frozen_string_literal: true

class AuditEventService
  # Instantiates a new service
  #
  # @param [User] author the user who authors the change
  # @param [User, Project, Group] entity the scope which audit event belongs to
  #   This param is also used to determine the visibility of the audit event.
  #   - Project: events are visible at Project and Instance level
  #   - Group: events are visible at Group and Instance level
  #   - User: events are visible at Instance level
  # @param [Hash] details extra data of audit event
  #
  # @return [AuditEventService]
  def initialize(author, entity, details = {})
    @author = build_author(author)
    @entity = entity
    @details = details
  end

  # Builds the @details attribute for authentication
  #
  # This uses the @author as the target object being audited
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

  def build_author(author)
    case author
    when User
      author.impersonated? ? Gitlab::Audit::ImpersonatedAuthor.new(author) : author
    else
      Gitlab::Audit::UnauthenticatedAuthor.new(name: author)
    end
  end

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
