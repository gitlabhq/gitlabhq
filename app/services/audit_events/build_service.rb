# frozen_string_literal: true

module AuditEvents
  class BuildService
    include ::Gitlab::Audit::ScopeValidation

    # Handle missing attributes
    MissingAttributeError = Class.new(StandardError)

    # Audit events live in one table per scope. Keys are scope class names, which
    # are also the values the scoped models report as `entity_type`.
    ENTITY_TYPE_TO_MODEL = {
      'Project' => ::AuditEvents::ProjectAuditEvent,
      'Group' => ::AuditEvents::GroupAuditEvent,
      'User' => ::AuditEvents::UserAuditEvent,
      # Gitlab::Audit::InstanceScope is EE-only, so the name is hardcoded here.
      'Gitlab::Audit::InstanceScope' => ::AuditEvents::InstanceAuditEvent
    }.freeze

    # instance_audit_events has no scope column, hence no InstanceScope entry.
    ENTITY_TYPE_TO_SCOPE_COLUMN = {
      'Project' => :project_id,
      'Group' => :group_id,
      'User' => :user_id
    }.freeze

    # @raise [MissingAttributeError] when required attributes are blank
    #
    # @return [BuildService]
    def initialize(
      author:, scope:, target:, message:,
      created_at: DateTime.current, additional_details: {}, ip_address: nil, target_details: nil)
      raise MissingAttributeError, "author" if author.blank?
      raise MissingAttributeError, "target" if target.blank?
      raise MissingAttributeError, "message" if message.blank?

      validate_scope!(scope)

      @author = build_author(author)
      @scope = scope
      @target = build_target(target)
      @ip_address = ip_address || build_ip_address
      @message = build_message(message)
      @created_at = created_at
      @additional_details = additional_details
      @target_details = target_details
    end

    # Create an unsaved audit event for the table backing the scope
    #
    # @return [AuditEvents::ProjectAuditEvent, AuditEvents::GroupAuditEvent,
    #   AuditEvents::UserAuditEvent, AuditEvents::InstanceAuditEvent]
    def execute
      ENTITY_TYPE_TO_MODEL.fetch(entity_type).new(payload)
    end

    private

    def entity_type
      @scope.class.name
    end

    def payload
      base_payload.merge(details: base_details_payload)
    end

    # target_*, entity_path and author_name columns are filled in from `details`
    # by AuditEvents::CommonModel#parallel_persist when the event is validated.
    def base_payload
      {
        author_id: @author.id,
        author_name: @author.name,
        event_name: @additional_details[:event_name],
        created_at: @created_at
      }.merge(scope_payload)
    end

    def scope_payload
      column = ENTITY_TYPE_TO_SCOPE_COLUMN[entity_type]
      return {} unless column

      { column => @scope.id }
    end

    def base_details_payload
      @additional_details.merge({
        author_name: @author.name,
        author_class: @author.class.name,
        target_id: @target.id,
        target_type: @target.type,
        target_details: @target_details || @target.details,
        custom_message: @message
      })
    end

    def build_author(author)
      author.id = -2 if author.instance_of? DeployToken
      author.id = -3 if author.instance_of? DeployKey

      author
    end

    def build_target(target)
      return target if target.is_a? ::Gitlab::Audit::NullTarget

      ::Gitlab::Audit::Target.new(target)
    end

    def build_message(message)
      message
    end

    def build_ip_address
      Gitlab::RequestContext.instance.client_ip || @author.current_sign_in_ip
    end
  end
end

AuditEvents::BuildService.prepend_mod_with('AuditEvents::BuildService')
