# frozen_string_literal: true

module BulkImports
  module Common
    module Transformers
      class MemberAttributesTransformer
        def transform(context, data)
          return data if context.importer_user_mapping_enabled?

          user = find_user(data&.dig('user', 'public_email'))
          access_level = data&.dig('access_level', 'integer_value')

          return unless data
          return unless user
          return unless valid_access_level?(access_level)

          cache_source_user_data(data, user, context)

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

        def cache_source_user_data(data, user, context)
          gid = data&.dig('user', 'user_gid')

          return unless gid

          source_user_id = GlobalID.parse(gid).model_id
          source_username = data&.dig('user', 'username')

          mapper = ::BulkImports::UsersMapper.new(context: context)

          mapper.cache_source_user_id(source_user_id, user.id)
          return unless source_username
          return if source_username == user.username

          mapper.cache_source_username(source_username, user.username)
        end
      end
    end
  end
end
