# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class NotesType < BaseObject
        graphql_name 'WorkItemWidgetNotes'
        description 'Represents a notes widget'

        implements ::Types::WorkItems::WidgetInterface

        def self.authorization_scopes
          super + [:ai_workflows]
        end

        field :discussion_locked, GraphQL::Types::Boolean,
          null: true,
          description: 'Discussion lock attribute of the work item.'

        # This field loads user comments, system notes and resource events as a discussion for an work item,
        # raising the complexity considerably. In order to discourage fetching this field as part of fetching
        # a list of issues we raise the complexity
        field :discussions, ::Types::Notes::DiscussionType.connection_type,
          null: true,
          skip_type_authorization: [:read_note, :read_emoji],
          description: "Discussions on this work item.",
          resolver: Resolvers::WorkItems::WorkItemDiscussionsResolver,
          connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension
        field :notes, ::Types::Notes::NoteType.connection_type,
          scopes: [:api, :read_api, :ai_workflows],
          null: false,
          description: "Notes on this work item.",
          resolver: Resolvers::Noteable::NotesResolver
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
