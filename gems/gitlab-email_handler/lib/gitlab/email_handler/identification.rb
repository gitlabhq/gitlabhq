# frozen_string_literal: true

require_relative 'reply_key'
require_relative 'target'

module Gitlab
  module EmailHandler
    # Result of parsing an incoming email key. Carries the handler that matched
    # and the captures relevant to that handler. The captures are handler
    # specific (project_id, project_path, reply_key, namespace_id, etc.).
    #
    # `#target` returns the identified Target (the resource that owns the email),
    # or nil when the email can't be identified (legacy reply keys without an
    # encoded namespace):
    #
    #   - Target.project_id   - project id encoded directly in the key
    #   - Target.namespace_id - decoded offline from a partitioned reply key
    #   - Target.route        - full project/group path (located by its top-level
    #                           namespace)
    #   - Target.service_desk_project_key_address_slug
    #                         - opaque service desk project key, matched verbatim
    #                           against the claimed
    #                           service_desk_settings.project_key_address_slug
    #   - nil                 - cannot be identified
    Identification = Data.define(:handler, :attributes) do
      def [](key)
        attributes[key]
      end

      def project_id
        attributes[:project_id]
      end

      def project_path
        attributes[:project_path]
      end

      def project_slug
        attributes[:project_slug]
      end

      def incoming_email_token
        attributes[:incoming_email_token]
      end

      # Decodes the base36 namespace_id encoded in partitioned reply keys.
      # Returns nil for legacy reply keys and partitioned keys that don't
      # encode a namespace id.
      def decoded_namespace_id
        encoded = attributes[:namespace_id]
        return unless encoded

        encoded.to_i(ReplyKey::INTEGER_CONVERT_BASE)
      end

      # The identified Target for this email, or nil when it can't be identified.
      def target
        namespace_id = decoded_namespace_id

        if namespace_id
          Target.namespace_id(namespace_id)
        elsif project_id
          Target.project_id(project_id)
        elsif project_path
          Target.route(project_path)
        elsif attributes[:project_key_address_slug]
          Target.service_desk_project_key_address_slug(attributes[:project_key_address_slug])
        end
      end
    end
  end
end
