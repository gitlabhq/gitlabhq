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
    @ip_address = resolve_ip_address(@author)
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
  # @return [AuditEvent] persited if saves and non-persisted if fails
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
      entity_type: @entity.class.name
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
    return if Gitlab::Database.main.read_only?

    event = AuditEvent.new(base_payload.merge(details: @details))
    save_or_track event

    event
  end

  def log_authentication_event_to_database
    return unless Gitlab::Database.main.read_write? && authentication_event?

    event = AuthenticationEvent.new(authentication_event_payload)
    save_or_track event

    event
  end

  def save_or_track(event)
    event.save!
  rescue StandardError => e
    Gitlab::ErrorTracking.track_exception(e, audit_event_type: event.class.to_s)
  end
end

AuditEventService.prepend_mod_with('AuditEventService')
