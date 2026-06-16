# frozen_string_literal: true

module Authz
  module Glaz
    class PermissionCheck
      def initialize(subject, object, permission)
        @subject = subject
        @object = object
        @permission = permission
      end

      def allowed?
        result[:allowed]
      end

      def denied?
        !allowed?
      end

      def reason
        result[:reason]
      end

      private

      attr_reader :subject, :object, :permission

      def result
        @result ||= Gitlab::Glaz.check_permission(
          subject_uuid: build_uuidv7(subject),
          object_uuid: build_uuidv7(object),
          permission: permission,
          context: object_context
        )
      end

      def object_context
        raise ArgumentError, "no Glaz context for #{object.class}" unless object.is_a?(::Project)

        { project: { archived: object.self_or_ancestors_archived? } }
      end

      def build_uuidv7(model)
        seed = authz_seed(model)
        ts_hex = format("%012x", (model.created_at.to_r * 1000).to_i)
        digest = OpenSSL::Digest::SHA256.hexdigest(seed)

        # RFC 9562 variant: the top two bits are fixed to `10` (so the nibble is
        # 8/9/a/b); the remaining two bits are taken from the digest to stay both
        # deterministic and spec-compliant.
        variant = (0x8 | (digest[3].to_i(16) & 0x3)).to_s(16)

        "#{ts_hex[0, 8]}-#{ts_hex[8, 4]}-7#{digest[0, 3]}-#{variant}#{digest[4, 3]}-#{digest[7, 12]}"
      end

      def authz_seed(model)
        "#{model.class.name}:#{namespace_id_for(model)}"
      end

      def namespace_id_for(model)
        case model
        when ::User    then model.namespace_id
        when ::Project then model.project_namespace_id
        else raise ArgumentError, "no Glaz namespace id for #{model.class}"
        end
      end
    end
  end
end
