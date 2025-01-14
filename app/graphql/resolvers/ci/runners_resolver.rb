# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnersResolver < BaseResolver
      include LooksAhead
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Ci::RunnerType.connection_type, null: true

      argument :active, ::GraphQL::Types::Boolean,
        required: false,
        description: 'Filter runners by `active` (true) or `paused` (false) status.',
        deprecated: { reason: :renamed, replacement: 'paused', milestone: '14.8' }

      argument :paused, ::GraphQL::Types::Boolean,
        required: false,
        description: 'Filter runners by `paused` (true) or `active` (false) status.'

      argument :status, ::Types::Ci::RunnerStatusEnum,
        required: false,
        description: 'Filter runners by status.'

      argument :type, ::Types::Ci::RunnerTypeEnum,
        required: false,
        description: 'Filter runners by type.'

      argument :tag_list, [GraphQL::Types::String],
        required: false,
        description: 'Filter by tags associated with the runner (comma-separated or array).'

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Filter by full token or partial text in description field.'

      argument :sort, ::Types::Ci::RunnerSortEnum,
        required: false,
        description: 'Sort order of results.'

      argument :upgrade_status, ::Types::Ci::RunnerUpgradeStatusEnum,
        required: false,
        description: 'Filter by upgrade status.'

      argument :creator_id, ::Types::GlobalIDType[::User].as('UserID'),
        required: false,
        description: 'Filter runners by creator ID.'

      argument :creator_username, GraphQL::Types::String,
        required: false,
        description: 'Filter runners by creator username.',
        experiment: { milestone: '16.7' }

      argument :version_prefix, GraphQL::Types::String,
        required: false,
        description: "Filter runners by version. Runners that contain runner managers with the version at " \
          "the start of the search term are returned. For example, the search term '14.' returns " \
          "runner managers with versions '14.11.1' and '14.2.3'.",
        experiment: { milestone: '16.6' }

      argument :owner_full_path, GraphQL::Types::String,
        required: false,
        description: 'Filter runners by owning project or group.',
        experiment: { milestone: '17.8' }

      argument :owner_wildcard, ::Types::Ci::RunnerOwnerWildcardEnum,
        required: false,
        description: 'Filter runners by owner wildcard.',
        experiment: { milestone: '17.8' }

      def ready?(**args)
        return true unless args[:owner_full_path].present? && args[:owner_wildcard].present?

        raise Gitlab::Graphql::Errors::ArgumentError,
          'The ownerFullPath and ownerWildcardPath arguments are mutually exclusive.'
      end

      def resolve_with_lookahead(**args)
        apply_lookahead(
          ::Ci::RunnersFinder
            .new(current_user: current_user, params: runners_finder_params(args))
            .execute)
      rescue Gitlab::Access::AccessDeniedError
        handle_access_denied_error!
      end

      protected

      def handle_access_denied_error!
        raise_resource_not_available_error!
      end

      def runners_finder_params(params)
        # Give preference to paused argument over the deprecated 'active' argument
        paused = params.fetch(:paused, params[:active] ? !params[:active] : nil)
        owner = {
          full_path: params[:owner_full_path],
          wildcard: params[:owner_wildcard]
        }.compact

        {
          active: paused.nil? ? nil : !paused,
          status_status: params[:status]&.to_s,
          type_type: params[:type],
          tag_name: params[:tag_list],
          upgrade_status: params[:upgrade_status],
          search: params[:search],
          sort: params[:sort]&.to_s,
          creator_id:
            params[:creator_id] ? ::GitlabSchema.parse_gid(params[:creator_id], expected_type: ::User).model_id : nil,
          creator_username: params[:creator_username],
          version_prefix: params[:version_prefix],
          owner: owner.presence,
          preload: {} # we'll handle preloading ourselves
        }.compact
         .merge(parent_param)
      end

      def parent_param
        return {} unless parent

        raise "Unexpected parent type: #{parent.class}"
      end

      private

      def parent
        object.respond_to?(:sync) ? object.sync : object
      end

      def preloads
        super.merge({
          created_by: [:creator],
          tag_list: [:tags]
        })
      end
    end
  end
end

Resolvers::Ci::RunnersResolver.prepend_mod
