# frozen_string_literal: true

module Types
  module WebHooks
    module HookType
      extend ActiveSupport::Concern

      included do
        field :url, GraphQL::Types::String,
          null: false,
          description: 'URL of the webhook.'

        field :name, GraphQL::Types::String,
          null: true,
          description: 'Name of the webhook.'

        field :description, GraphQL::Types::String,
          null: true,
          description: 'Description of the webhook.'

        field :created_at, Types::TimeType,
          null: false,
          description: 'Timestamp of when the webhook was created.'

        field :enable_ssl_verification, GraphQL::Types::Boolean,
          null: true,
          description: 'Whether SSL verification is done when triggering the webhook.'

        field :alert_status, Types::WebHooks::AlertStatusEnum,
          null: false,
          description: 'Auto-disabling status of the webhook.'

        field :disabled_until, Types::TimeType,
          null: true,
          description: 'Timestamp when the webhook will be automatically re-enabled if temporarily disabled.'

        field :url_variables, [Types::WebHooks::UrlVariableType],
          null: true,
          description: 'List of URL variable masks to hide sensitive portions of the webhook URL.',
          method: :masked_url_variables

        field :custom_headers, [Types::WebHooks::CustomHeaderType],
          null: true,
          description: 'List of custom header names for the webhook.',
          method: :masked_custom_headers

        field :custom_webhook_template, GraphQL::Types::String,
          null: true,
          description: 'Custom payload template for the webhook request body.'

        field :push_events_branch_filter, GraphQL::Types::String,
          null: true,
          description: 'Trigger hook on push events for matching branches only.'

        field :branch_filter_strategy, Types::WebHooks::BranchFilterStrategyEnum,
          null: false,
          description: 'Strategy for filtering push events by branch name.'

        field :push_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on push events.'

        field :tag_push_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on tag push events.',
          resolver_method: :resolve_nil_tag_push_events

        field :merge_requests_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on merge request events.'

        field :issues_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on issues events.'

        field :confidential_issues_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on confidential issues events.'

        field :note_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on note events.'

        field :confidential_note_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on confidential note events.',
          resolver_method: :resolve_nil_confidential_note_events

        field :pipeline_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on pipeline events.'

        field :wiki_page_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on wiki page events.'

        field :deployment_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on deployment events.'

        field :feature_flag_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on feature flag events.'

        field :job_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on job events.'

        field :releases_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on releases events.'

        field :milestone_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on milestone events.'

        field :emoji_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on emoji events.'

        field :resource_access_token_events, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the webhook is triggered on resource access token events.'

        field :webhook_events, Types::WebHooks::EventType.connection_type,
          null: true,
          description: 'List of recent webhook events. ' \
            'This field can only be resolved for one webhook in any single request.',
          resolver: Resolvers::WebHooks::EventsResolver,
          max_page_size: 20 do
          extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
        end

        field :webhook_event, Types::WebHooks::EventType,
          null: true,
          description: 'A single webhook event.',
          resolver: Resolvers::WebHooks::EventsResolver.single

        def resolve_nil_confidential_note_events
          resolve_nil_events(object.confidential_note_events)
        end

        def resolve_nil_tag_push_events
          resolve_nil_events(object.tag_push_events)
        end

        private

        def resolve_nil_events(events_value)
          events_value || false
        end
      end
    end
  end
end
