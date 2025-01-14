# frozen_string_literal: true

module Authn
  module TokenField
    class Insecure < Base
      def find_token_authenticatable(token, unscoped = false)
        relation(unscoped).find_by(@token_field => token) if token # rubocop:disable CodeReuse/ActiveRecord -- This is meant to be used inside an AR model.
      end

      def get_token(token_owner_record)
        token_owner_record.read_attribute(@token_field)
      end

      def set_token(token_owner_record, token)
        token_owner_record[@token_field] = token if token
      end

      protected

      def token_set?(token_owner_record)
        token_owner_record.read_attribute(@token_field).present?
      end
    end
  end
end
