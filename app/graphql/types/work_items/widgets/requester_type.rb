# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class RequesterType < BaseObject
        graphql_name 'WorkItemWidgetRequester'
        description 'Represents the requester widget'

        authorize_granular_token skip_reason: :parent_authorizes

        implements ::Types::WorkItems::WidgetInterface

        field :email, GraphQL::Types::String,
          null: true,
          description: 'Email address of the non-GitLab user who requested the work item. ' \
            'For guests, the email address is obfuscated.'

        def email
          email = object.email
          return if email.blank?
          return email if Ability.allowed?(current_user, :read_external_emails, object.work_item.project)

          Gitlab::Utils::Email.obfuscated_email(email, deform: true)
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
