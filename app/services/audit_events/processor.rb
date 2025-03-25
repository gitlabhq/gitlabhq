# frozen_string_literal: true

module AuditEvents
  class Processor
    def self.fetch(audit_event_id: nil, audit_event_json: nil, model_class: nil)
      return fetch_from_json(audit_event_json) if audit_event_json.present?
      return fetch_from_id(audit_event_id, model_class) if audit_event_id.present?

      nil
    rescue StandardError => e
      ::Gitlab::ErrorTracking.track_exception(
        e,
        audit_event_id: audit_event_id,
        model_class: model_class,
        audit_event_json: audit_event_json&.truncate(100)
      )
      nil
    end

    def self.fetch_from_id(audit_event_id, model_class)
      if model_class.present?
        model_class.constantize.find(audit_event_id)
      else
        ::AuditEvent.find_by_id(audit_event_id)
      end
    rescue ActiveRecord::RecordNotFound => e
      ::Gitlab::ErrorTracking.track_exception(
        e,
        audit_event_id: audit_event_id,
        model_class: model_class
      )
      nil
    end

    def self.fetch_from_json(audit_event_json)
      parsed_json = ::Gitlab::Json.parse(audit_event_json).with_indifferent_access
      model_class, entity = determine_audit_model_entity(parsed_json)

      if ::Gitlab::Audit::FeatureFlags.stream_from_new_tables?(entity)
        create_scoped_audit_event(model_class, parsed_json)
      else
        filtered_json = parsed_json.except(:group_id, :project_id, :user_id)
        ::AuditEvent.new(filtered_json)
      end
    rescue JSON::ParserError, ActiveRecord::RecordNotFound => e
      ::Gitlab::ErrorTracking.track_exception(
        e,
        audit_event_json: audit_event_json&.truncate(100)
      )
      nil
    end

    def self.determine_audit_model_entity(audit_event_json)
      entity_mapping = {
        group_id: [::AuditEvents::GroupAuditEvent, ->(id) { ::Group.find(id) }],
        project_id: [::AuditEvents::ProjectAuditEvent, ->(id) { ::Project.find(id) }],
        user_id: [::AuditEvents::UserAuditEvent, ->(id) { ::User.find(id) }]
      }

      entity_type, (model_class, entity_finder) = entity_mapping.find do |key, _|
        audit_event_json[key].present?
      end

      if entity_type && entity_finder
        entity = entity_finder.call(audit_event_json[entity_type])
        [model_class, entity]
      else
        [::AuditEvents::InstanceAuditEvent, :instance]
      end
    end

    def self.create_scoped_audit_event(model_class, audit_event_json)
      excluded_fields_mapping = {
        ::AuditEvents::GroupAuditEvent => [:project_id, :user_id, :entity_type, :entity_id],
        ::AuditEvents::ProjectAuditEvent => [:group_id, :user_id, :entity_type, :entity_id],
        ::AuditEvents::UserAuditEvent => [:group_id, :project_id, :entity_type, :entity_id],
        ::AuditEvents::InstanceAuditEvent => [:group_id, :project_id, :user_id, :entity_type, :entity_id]
      }

      excluded_fields = excluded_fields_mapping[model_class] || [:entity_type, :entity_id]
      filtered_json = audit_event_json.except(*excluded_fields)
      model_class.new(filtered_json)
    end
  end
end
