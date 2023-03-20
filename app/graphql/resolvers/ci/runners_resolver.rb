# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnersResolver < BaseResolver
      include LooksAhead

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

      def resolve_with_lookahead(**args)
        apply_lookahead(
          ::Ci::RunnersFinder
            .new(current_user: current_user, params: runners_finder_params(args))
            .execute)
      end

      protected

      def runners_finder_params(params)
        # Give preference to paused argument over the deprecated 'active' argument
        paused = params.fetch(:paused, params[:active] ? !params[:active] : nil)

        {
          active: paused.nil? ? nil : !paused,
          status_status: params[:status]&.to_s,
          type_type: params[:type],
          tag_name: params[:tag_list],
          upgrade_status: params[:upgrade_status],
          search: params[:search],
          sort: params[:sort]&.to_s,
          preload: false # we'll handle preloading ourselves
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

      def nested_preloads
        {
          created_by: {
            creator: {
              full_path: [:route],
              web_path: [:route],
              web_url: [:route]
            }
          },
          owner_project: {
            owner_project: {
              full_path: [:route, { namespace: [:route] }],
              web_url: [:route, { namespace: [:route] }]
            }
          }
        }
      end
    end
  end
end
