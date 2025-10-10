# frozen_string_literal: true

module Mutations
  module Users
    module GroupCallouts
      class Create < ::Mutations::BaseMutation
        graphql_name 'UserGroupCalloutCreate'

        include Gitlab::Graphql::Authorize::AuthorizeResource

        argument :feature_name,
          GraphQL::Types::String,
          required: true,
          description: "Feature name you want to dismiss the callout for."
        argument :group_id,
          ::Types::GlobalIDType[::Group],
          required: true,
          description: 'Group for the callout.'

        field :user_group_callout,
          Types::Users::GroupCalloutType,
          null: false,
          description: 'User group callout dismissed.'

        authorize :read_group

        def resolve(feature_name:, group_id:)
          group = authorized_find!(id: group_id)

          callout = ::Users::DismissGroupCalloutService.new(
            container: nil, current_user: current_user, params: { feature_name: feature_name, group_id: group.id }
          ).execute
          errors = errors_on_object(callout)

          {
            user_group_callout: callout,
            errors: errors
          }
        end
      end
    end
  end
end
