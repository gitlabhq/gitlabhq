# frozen_string_literal: true

module Types
  module Namespaces
    module MarkdownPaths
      include ::Types::BaseInterface
      include ::IssuablesHelper

      graphql_name 'MarkdownPaths'

      TYPE_MAPPINGS = {
        ::Group => ::Types::Namespaces::MarkdownPaths::GroupNamespaceMarkdownPathsType,
        ::Namespaces::ProjectNamespace => ::Types::Namespaces::MarkdownPaths::ProjectNamespaceMarkdownPathsType,
        ::Namespaces::UserNamespace => ::Types::Namespaces::MarkdownPaths::UserNamespaceMarkdownPathsType
      }.freeze

      NEW_WORK_ITEM_IID = 'new-work-item-iid'

      field :uploads_path,
        GraphQL::Types::String,
        null: true,
        description: 'Uploads path for a given namespace.',
        fallback_value: nil

      field :markdown_preview_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path for the markdown preview for given namespace.',
        fallback_value: nil do
          argument :iid, GraphQL::Types::String,
            required: false,
            description: 'IID of the target item for markdown preview.'
        end

      field :autocomplete_sources_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path for autocomplete sources for a given namespace.',
        fallback_value: nil do
          argument :autocomplete_type, Types::Namespaces::MarkdownPaths::AutocompleteTypeEnum,
            required: true,
            description: 'Type of autocomplete source (e.g., members, labels, etc.).'
          argument :iid, GraphQL::Types::String,
            required: false,
            description: 'IID of the work item.'
          argument :work_item_type_id, GraphQL::Types::String,
            required: false,
            description: 'ID of the work item type.'
        end

      def self.type_mappings
        TYPE_MAPPINGS
      end

      def self.resolve_type(object, _context)
        type_mappings[object.class] || raise("Unknown GraphQL type for namespace type #{object.class}")
      end

      orphan_types(*type_mappings.values)

      private

      def url_helpers
        ::Gitlab::Routing.url_helpers
      end

      def build_autocomplete_params(iid:, work_item_type_id:)
        params = { type: 'WorkItem' }

        if new_work_item?(iid) && work_item_type_id
          params[:work_item_type_id] = extract_id_from_gid(work_item_type_id)
        elsif iid
          params[:type_id] = iid
        end

        params
      end

      def extract_id_from_gid(gid)
        GlobalID.parse(gid)&.model_id
      end

      def new_work_item?(iid)
        iid == NEW_WORK_ITEM_IID
      end
    end
  end
end
