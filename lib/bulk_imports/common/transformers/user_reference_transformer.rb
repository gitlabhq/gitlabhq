# frozen_string_literal: true

# UserReferenceTransformer replaces specified user
# reference key with a user id being either:
#   - A user id found by `public_email` in the group
#   - Current user id
# under a new key `"#{@reference}_id"`.
module BulkImports
  module Common
    module Transformers
      class UserReferenceTransformer
        DEFAULT_REFERENCE = 'user'

        def initialize(options = {})
          @reference = options[:reference].to_s.presence || DEFAULT_REFERENCE
          @suffixed_reference = "#{@reference}_id"
        end

        def transform(context, data)
          return unless data

          user = find_user(context, data&.dig(@reference, 'public_email')) || context.current_user

          data
            .except(@reference)
            .merge(@suffixed_reference => user.id)
        end

        private

        def find_user(context, email)
          return if email.blank?

          context.group.users.find_by_any_email(email, confirmed: true) # rubocop: disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
