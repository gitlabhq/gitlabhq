module Gitlab
  module GitalyClient
    class Diff
      FIELDS = %i(from_path to_path old_mode new_mode from_id to_id patch overflow_marker collapsed).freeze

      attr_accessor(*FIELDS)

      def initialize(params)
        params.each do |key, val|
          public_send(:"#{key}=", val) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def ==(other)
        FIELDS.all? do |field|
          public_send(field) == other.public_send(field) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
