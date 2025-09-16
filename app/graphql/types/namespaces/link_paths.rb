# frozen_string_literal: true

module Types
  module Namespaces
    module LinkPaths
      include ::Types::BaseInterface

      graphql_name 'NamespacesLinkPaths'

      # rubocop: disable Graphql/AuthorizeTypes, GraphQL/GraphqlName -- helper class
      class UrlHelpers
        include GitlabRoutingHelper
        include Gitlab::Routing

        # required for the new_comment_template_paths
        include ::IssuablesHelper

        # required for the new_comment_template_paths
        public :new_comment_template_paths

        attr_reader :current_user

        def initialize(current_user)
          @current_user = current_user
        end
      end
      private_constant :UrlHelpers
      # rubocop: enable Graphql/AuthorizeTypes, GraphQL/GraphqlName

      TYPE_MAPPINGS = {
        ::Group => ::Types::Namespaces::LinkPaths::GroupNamespaceLinksType,
        ::Namespaces::ProjectNamespace => ::Types::Namespaces::LinkPaths::ProjectNamespaceLinksType,
        ::Namespaces::UserNamespace => ::Types::Namespaces::LinkPaths::UserNamespaceLinksType
      }.freeze

      field :issues_list,
        GraphQL::Types::String,
        null: true,
        description: 'Namespace issues_list.',
        fallback_value: nil

      field :labels_manage,
        GraphQL::Types::String,
        null: true,
        description: 'Namespace labels_manage.',
        fallback_value: nil

      field :new_project,
        GraphQL::Types::String,
        null: true,
        description: 'Namespace new_project.',
        fallback_value: nil

      field :new_comment_template,
        [Types::Namespaces::LinkPaths::CommentTemplateType],
        null: true,
        description: 'Namespace new_comment_template_paths.',
        fallback_value: nil

      field :register,
        GraphQL::Types::String,
        null: true,
        description: 'Namespace register_path.'

      field :report_abuse,
        GraphQL::Types::String,
        null: true,
        description: 'Namespace report_abuse.'

      field :sign_in,
        GraphQL::Types::String,
        null: true,
        description: 'Namespace sign_in_path.'

      field :contribution_guide_path,
        GraphQL::Types::String,
        null: true,
        description: 'Namespace contribution guide path.',
        fallback_value: nil,
        calls_gitaly: true

      field :emails_help_page_path,
        GraphQL::Types::String,
        null: true,
        description: 'Help page path for emails.'

      field :markdown_help_path,
        GraphQL::Types::String,
        null: true,
        description: 'Help page path for Markdown.'

      field :quick_actions_help_path,
        GraphQL::Types::String,
        null: true,
        description: 'Help page path for quick actions.'

      field :user_export_email,
        GraphQL::Types::String,
        null: true,
        description: 'User email for export CSV. Returns `null` for user namespaces.',
        fallback_value: nil,
        experiment: { milestone: '18.3' }

      field :rss_path,
        GraphQL::Types::String,
        null: true,
        description: 'RSS path for work items.',
        fallback_value: nil,
        experiment: { milestone: '18.4' }

      field :calendar_path,
        GraphQL::Types::String,
        null: true,
        description: 'Calendar path for work items.',
        fallback_value: nil,
        experiment: { milestone: '18.4' }

      def self.type_mappings
        TYPE_MAPPINGS
      end

      def self.resolve_type(object, _context)
        type_mappings[object.class] || raise("Unknown GraphQL type for namespace type #{object.class}")
      end

      orphan_types(*type_mappings.values)

      def register
        url_helpers.new_user_registration_path(redirect_to_referer: 'yes')
      end

      def report_abuse
        url_helpers.add_category_abuse_reports_path
      end

      def sign_in
        url_helpers.new_user_session_path(redirect_to_referer: 'yes')
      end

      def emails_help_page_path
        url_helpers.help_page_path('development/emails.md', anchor: 'email-namespace')
      end

      def markdown_help_path
        url_helpers.help_page_path('user/markdown.md')
      end

      def quick_actions_help_path
        url_helpers.help_page_path('user/project/quick_actions.md')
      end

      def user_export_email
        current_user&.notification_email_or_default
      end

      private

      def url_helpers
        @url_helpers ||= UrlHelpers.new(current_user)
      end
    end
  end
end

::Types::Namespaces::LinkPaths.prepend_mod
