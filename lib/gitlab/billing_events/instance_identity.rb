# frozen_string_literal: true

module Gitlab
  module BillingEvents
    # The instance-level half of a billing event: who is reporting, rather than what was
    # used. The air-gapped export derives these fields from here too, so an exported
    # instance resolves to the same CustomersDot subscription as a streamed one.
    class InstanceIdentity
      REALM_MAP = {
        'saas' => 'SaaS',
        'self-managed' => 'SM',
        'dedicated' => 'Dedicated'
      }.freeze

      def self.to_h
        new.to_h
      end

      def to_h
        {
          instance_id: ::Gitlab::GlobalAnonymousId.instance_id,
          unique_instance_id: unique_instance_id,
          host_name: Gitlab.config.gitlab.host,
          instance_version: Gitlab.version_info.to_s,
          realm: realm,
          deployment_type: deployment_type
        }
      end

      private

      def unique_instance_id
        ::Gitlab::GlobalAnonymousId.instance_uuid
      end

      def realm
        'SM'
      end

      def deployment_type
        'self-managed'
      end
    end
  end
end

Gitlab::BillingEvents::InstanceIdentity.prepend_mod
