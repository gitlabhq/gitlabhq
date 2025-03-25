# frozen_string_literal: true

module Gitlab
  module Audit
    module FeatureFlags
      def self.stream_from_new_tables?(entity)
        entity_scope = if entity.nil? || entity.instance_of?(::Gitlab::Audit::NullEntity)
                         :instance
                       elsif entity.instance_of?(::Gitlab::Audit::InstanceScope)
                         :instance
                       else
                         entity
                       end

        ::Feature.enabled?(:stream_audit_events_from_new_tables, entity_scope)
      end
    end
  end
end
