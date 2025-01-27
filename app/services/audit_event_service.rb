# frozen_string_literal: true

class AuditEventService
  include AuditEventSaveType
  include ::Gitlab::Audit::Logging
  include ::Gitlab::Audit::ScopeValidation

  # Instantiates a new service
  #
  # @deprecated This service is deprecated. Use Gitlab::Audit::Auditor instead.
  # More information: https://docs.gitlab.com/ee/development/audit_event_guide/#how-to-instrument-new-audit-events
  #
  # @param [User, token String] author the entity who authors the change
  # @param [User, Project, Group] entity the scope which audit event belongs to
  #   This param is also used to determine the visibility of the audit event.
  #   - Project: events are visible at Project and Instance level
  #   - Group: events are visible at Group and Instance level
  #   - User: events are visible at Instance level
  # @param [Hash] details extra data of audit event
  # @param [Symbol] save_type the type to save the event
  #   Can be selected from the following, :database, :stream, :database_and_stream .
  # @params [DateTime] created_at the time the action occured
  #
  # @return [AuditEventService]
  def initialize(author, entity, details = {}, save_type = :database_and_stream, created_at = DateTime.current)
    @author = build_author(author)
    @entity = entity
    @details = details
    @ip_address = resolve_ip_address(@author)
    @save_type = save_type
    @created_at = created_at

    validate_scope!(@entity)
  end

  # Builds the @details attribute for authentication
  #
  # This uses the @author as the target object being audited
  #
  # @return [AuditEventService]
  def for_authentication
    mark_as_authentication_event!

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
  # @return [AuditEvent] persisted if saves and non-persisted if fails
  def security_event
    log_security_event_to_file
    log_authentication_event_to_database
    log_security_event_to_database
  end

  # Writes event to a file
  def log_security_event_to_file
    file_logger.info(base_payload.merge(formatted_details))
  end

  private

  attr_reader :ip_address

  def build_author(author)
    case author
    when User
      author.impersonated? ? Gitlab::Audit::ImpersonatedAuthor.new(author) : author
    else
      Gitlab::Audit::UnauthenticatedAuthor.new(name: author)
    end
  end

  def resolve_ip_address(author)
    Gitlab::RequestContext.instance.client_ip ||
      author.current_sign_in_ip
  end

  def base_payload
    {
      author_id: @author.id,
      author_name: @author.name,
      entity_id: @entity.id,
      entity_type: @entity.class.name,
      created_at: @created_at
    }
  end

  def authentication_event_payload
    {
      # @author can be a User or various Gitlab::Audit authors.
      # Only capture real users for successful authentication events.
      user: author_if_user,
      user_name: @author.name,
      ip_address: ip_address,
      result: AuthenticationEvent.results[:success],
      provider: @details[:with]
    }
  end

  def author_if_user
    @author if @author.is_a?(User)
  end

  def file_logger
    @file_logger ||= Gitlab::AuditJsonLogger.build
  end

  def formatted_details
    @details.merge(@details.slice(:from, :to).transform_values(&:to_s))
  end

  def mark_as_authentication_event!
    @authentication_event = true
  end

  def authentication_event?
    @authentication_event
  end

  def log_security_event_to_database
    return if Gitlab::Database.read_only?

    event = build_event
    save_or_track event
    log_to_new_tables([event], event.class.to_s) if should_save_database?(@save_type)
    event
  end

  def build_event
    AuditEvent.new(base_payload.merge(details: @details))
  end

  def stream_event_to_external_destinations(_event)
    # Defined in EE
  end

  def log_authentication_event_to_database
    return unless Gitlab::Database.read_write? && authentication_event?

    AuthenticationEvent.new(authentication_event_payload).tap do |event|
      save_or_track event
    end
  end

  def save_or_track(event)
    event.save! if should_save_database?(@save_type)
    stream_event_to_external_destinations(event) if should_save_stream?(@save_type)
  rescue StandardError => e
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, audit_event_type: event.class.to_s)

    nil
  end
end

AuditEventService.prepend_mod_with('AuditEventService')
