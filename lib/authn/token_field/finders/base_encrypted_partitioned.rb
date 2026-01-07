# frozen_string_literal: true

module Authn
  module TokenField
    module Finders
      class BaseEncryptedPartitioned < BaseEncrypted
        def execute
          if partition_key.present?
            record = partition_scope.find_by(encrypted_field => tokens) # rubocop:disable CodeReuse/ActiveRecord -- have to use find_by
            return record if record
          end

          base_scope.find_by(encrypted_field => tokens) # rubocop:disable CodeReuse/ActiveRecord -- have to use find_by
        end

        protected

        def partition_key
          raise NotImplementedError
        end

        def partition_scope
          raise NotImplementedError
        end
      end
    end
  end
end
