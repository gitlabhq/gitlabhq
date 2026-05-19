# frozen_string_literal: true

require 'active_support/core_ext/digest/uuid'
require 'active_support/core_ext/object/blank'

module Gitlab
  class UUID
    DEFAULT_NAMESPACE_ID = "a143e9e2-41b3-47bc-9a19-081d089229f4"

    UUID_PATTERN = /\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/i
    UUID_V5_PATTERN = /\h{8}-\h{4}-5\h{3}-\h{4}-\h{12}/

    class << self
      attr_writer :default_namespace_id

      def default_namespace_id
        @default_namespace_id ||= DEFAULT_NAMESPACE_ID
      end

      def urn
        "urn:uuid:#{Digest::UUID.uuid_v4}"
      end

      def v5(name, namespace_id: default_namespace_id)
        Digest::UUID.uuid_v5(namespace_id, name)
      end

      def uuid?(string)
        UUID_PATTERN.match?(string)
      end
    end
  end
end
