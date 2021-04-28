# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    prepend Gitlab::Graphql::Authorize::AuthorizeResource
    prepend Gitlab::Graphql::CopyFieldDescription
    prepend ::Gitlab::Graphql::GlobalIDCompatibility

    ERROR_MESSAGE = 'You cannot perform write operations on a read-only instance'

    field_class ::Types::BaseField

    field :errors, [GraphQL::STRING_TYPE],
          null: false,
          description: 'Errors encountered during execution of the mutation.'

    def current_user
      context[:current_user]
    end

    def api_user?
      context[:is_sessionless_user]
    end

    # Returns Array of errors on an ActiveRecord object
    def errors_on_object(record)
      record.errors.full_messages
    end

    def ready?(**args)
      auth = ::Gitlab::Graphql::Authorize::ObjectAuthorization.new(:execute_graphql_mutation, :api)

      if Gitlab::Database.read_only?
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, ERROR_MESSAGE
      elsif !auth.ok?(:global, current_user, scope_validator: context[:scope_validator])
        raise_resource_not_available_error!
      else
        true
      end
    end
  end
end
