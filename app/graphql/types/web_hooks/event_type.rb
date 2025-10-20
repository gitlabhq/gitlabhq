# frozen_string_literal: true

module Types
  module WebHooks
    class EventType < BaseObject
      graphql_name 'WebhookEvent'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_web_hook

      field :id, Types::GlobalIDType[::WebHookLog],
        null: false,
        description: 'Global ID of the webhook event.'

      field :trigger, GraphQL::Types::String,
        null: true,
        description: 'Trigger that caused webhook execution.'

      field :url, GraphQL::Types::String,
        null: true,
        description: 'URL used in webhook request.'

      # rubocop:disable GraphQL/ExtractType -- Not needed as these are read-only and lack consistent structures to reuse
      field :request_headers, [Types::WebHooks::EventHeaderType],
        null: true,
        description: 'HTTP Headers used in the webhook request.',
        method: :request_headers_list

      field :request_data, GraphQL::Types::String,
        null: true,
        description: 'Data sent in the webhook request.'

      field :response_headers, [Types::WebHooks::EventHeaderType],
        null: true,
        description: 'HTTP Headers from the webhook response.',
        method: :response_headers_list

      field :response_body, GraphQL::Types::String,
        null: true,
        description: 'Body of the webhook response.'

      field :response_status, GraphQL::Types::String,
        null: true,
        description: 'HTTP status of the webhook response.'
      # rubocop:enable GraphQL/ExtractType

      field :execution_duration, GraphQL::Types::Float,
        null: true,
        description: 'Webhook execution duration in seconds.'

      field :internal_error_message, GraphQL::Types::String,
        null: true,
        description: 'Internal error message that occurred while executing the webhook.'

      field :oversize, GraphQL::Types::Boolean,
        null: false,
        description: 'Whether request data was too large to be executed.',
        method: :oversize?

      field :created_at, Types::TimeType,
        null: false,
        description: 'Webhook request time.'
    end
  end
end
