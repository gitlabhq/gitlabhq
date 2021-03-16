# frozen_string_literal: true

module Mutations
  module UserCallouts
    class Create < ::Mutations::BaseMutation
      graphql_name 'UserCalloutCreate'

      argument :feature_name,
               GraphQL::STRING_TYPE,
               required: true,
               description: "The feature name you want to dismiss the callout for."

      field :user_callout, Types::UserCalloutType,
        null: false,
        description: 'The user callout dismissed.'

      def resolve(feature_name:)
        callout = Users::DismissUserCalloutService.new(
          container: nil, current_user: current_user, params: { feature_name: feature_name }
        ).execute
        errors = errors_on_object(callout)

        {
          user_callout: callout,
          errors: errors
        }
      end
    end
  end
end
