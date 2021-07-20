# frozen_string_literal: true

module BulkImports
  module Groups
    module Transformers
      class MemberAttributesTransformer
        def transform(context, data)
          data
            .then { |data| add_user(data, context) }
            .then { |data| add_access_level(data) }
            .then { |data| add_author(data, context) }
        end

        private

        def add_user(data, context)
          user = find_user(data&.dig('user', 'public_email'))

          return unless user

          cache_source_user_id(data, user, context)

          data
            .except('user')
            .merge('user_id' => user.id)
        end

        def find_user(email)
          return unless email

          User.find_by_any_email(email, confirmed: true)
        end

        def add_access_level(data)
          access_level = data&.dig('access_level', 'integer_value')

          return unless valid_access_level?(access_level)

          data.merge('access_level' => access_level)
        end

        def valid_access_level?(access_level)
          Gitlab::Access
            .options_with_owner
            .value?(access_level)
        end

        def add_author(data, context)
          return unless data

          data.merge('created_by_id' => context.current_user.id)
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
