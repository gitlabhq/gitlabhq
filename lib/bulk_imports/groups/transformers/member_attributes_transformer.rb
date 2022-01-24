# frozen_string_literal: true

module BulkImports
  module Groups
    module Transformers
      class MemberAttributesTransformer
        def transform(context, data)
          user = find_user(data&.dig('user', 'public_email'))
          access_level = data&.dig('access_level', 'integer_value')

          return unless data
          return unless user
          return unless valid_access_level?(access_level)

          cache_source_user_id(data, user, context)

          {
            user_id: user.id,
            access_level: access_level,
            created_at: data['created_at'],
            updated_at: data['updated_at'],
            expires_at: data['expires_at'],
            created_by_id: context.current_user.id
          }
        end

        private

        def find_user(email)
          return unless email

          User.find_by_any_email(email, confirmed: true)
        end

        def valid_access_level?(access_level)
          Gitlab::Access.options_with_owner.value?(access_level)
        end

        def cache_source_user_id(data, user, context)
          gid = data&.dig('user', 'user_gid')

          return unless gid

          source_user_id = GlobalID.parse(gid).model_id

          ::BulkImports::UsersMapper.new(context: context).cache_source_user_id(source_user_id, user.id)
        end
      end
    end
  end
end
