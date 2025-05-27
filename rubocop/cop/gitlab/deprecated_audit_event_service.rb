# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Checks for usage of the deprecated AuditEventService
      # and prevents new implementations from being added.
      #
      # @example
      #   # bad
      #   AuditEventService.new(...)
      #
      #   # good
      #   Gitlab::Audit::Auditor.audit { ... }
      #
      class DeprecatedAuditEventService < RuboCop::Cop::Base
        MSG = "AuditEventService is deprecated and new implementations are not allowed. " \
          "Instead please use Gitlab::Audit::Auditor. See " \
          "https://docs.gitlab.com/development/audit_event_guide/#how-to-instrument-new-audit-events"

        # @!method audit_event_service_usage?(node)
        def_node_matcher :audit_event_service_usage?, <<~PATTERN
          {
            (const nil? :AuditEventService)
            (const (cbase) :AuditEventService)
          }
        PATTERN

        # @!method audit_event_service_include?(node)
        def_node_matcher :audit_event_service_include?, <<~PATTERN
          (send nil? {:include :extend} #audit_event_service_usage?)
        PATTERN

        # @!method audit_event_service_new?(node)
        def_node_matcher :audit_event_service_new?, <<~PATTERN
          (call #audit_event_service_usage? :new ...)
        PATTERN

        def on_const(node)
          return unless audit_event_service_usage?(node)
          return if node.parent&.send_type? && [:include, :extend].include?(node.parent.method_name)

          add_offense(node)
        end

        def on_send(node)
          return unless audit_event_service_include?(node) || audit_event_service_new?(node)

          add_offense(node)
        end

        def on_csend(node)
          return unless audit_event_service_include?(node) || audit_event_service_new?(node)

          add_offense(node)
        end
      end
    end
  end
end
