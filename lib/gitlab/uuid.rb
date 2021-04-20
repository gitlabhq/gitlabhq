# frozen_string_literal: true

module Gitlab
  class UUID
    NAMESPACE_IDS = {
      development: "a143e9e2-41b3-47bc-9a19-081d089229f4",
      test: "a143e9e2-41b3-47bc-9a19-081d089229f4",
      staging: "a6930898-a1b2-4365-ab18-12aa474d9b26",
      production: "58dc0f06-936c-43b3-93bb-71693f1b6570"
    }.freeze

    UUID_V5_PATTERN = /\h{8}-\h{4}-5\h{3}-\h{4}-\h{12}/.freeze
    NAMESPACE_REGEX = /(\h{8})-(\h{4})-(\h{4})-(\h{4})-(\h{4})(\h{8})/.freeze
    PACK_PATTERN = "NnnnnN"

    class << self
      def v5(name, namespace_id: default_namespace_id)
        Digest::UUID.uuid_v5(namespace_id, name)
      end

      def v5?(string)
        string.match(UUID_V5_PATTERN).present?
      end

      private

      def default_namespace_id
        @default_namespace_id ||= begin
          namespace_uuid = NAMESPACE_IDS.fetch(Rails.env.to_sym)
          # Digest::UUID is broken when using a UUID as a namespace_id
          # https://github.com/rails/rails/issues/37681#issue-520718028
          namespace_uuid.scan(NAMESPACE_REGEX).flatten.map { |s| s.to_i(16) }.pack(PACK_PATTERN)
        end
      end
    end
  end
end
