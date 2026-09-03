# frozen_string_literal: true

module API
  module Ci
    # Kept separate from API::Ci::Pipelines on purpose: that class allows the
    # ai_workflows and mcp OAuth scopes on all GET routes, which must not
    # extend to this cross-project endpoint.
    class UserPipelines < ::API::Base
      helpers ::API::Helpers::Authz::PostfilteringHelpers

      before { authenticate! }

      resource :pipelines do
        desc 'List pipelines triggered by the authenticated user' do
          detail 'Lists recently created pipelines across all projects that were triggered by the authenticated ' \
            'user. By default, child pipelines are not included in the results. To return child pipelines, set ' \
            '`source` to `parent_pipeline`. This endpoint only supports keyset pagination.'
          success status: 200, model: Entities::Ci::UserPipeline
          failure [
            { code: 401, message: 'Unauthorized' }
          ]
          is_array true
          tags ['pipelines']
        end

        params do
          optional :source, type: String, values: ::Ci::Pipeline.sources.keys,
            desc: 'The source of pipelines',
            documentation: { example: 'push' }
          optional :created_before, type: DateTime,
            desc: 'Return pipelines created before the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ',
            documentation: { example: '2015-12-24T15:51:21.880Z' }
          optional :created_after, type: DateTime,
            desc: 'Return pipelines created after the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ',
            documentation: { example: '2015-12-24T15:51:21.880Z' }
          optional :order_by, type: String, values: %w[created_at], default: 'created_at',
            desc: 'Return pipelines ordered by `created_at`',
            documentation: { example: 'created_at' }
          optional :sort, type: String, values: %w[desc], default: 'desc',
            desc: 'Return pipelines sorted in `desc` order',
            documentation: { example: 'desc' }
          optional :cursor, type: String,
            desc: 'Cursor for obtaining the next set of records',
            documentation: { example: 'eyJpZCI6IjE0In0' }
          optional :per_page, type: Integer, default: 20, values: 1..100,
            desc: 'Number of items per page',
            documentation: { example: 20 }
        end

        route_setting :authorization, permissions: :read_pipeline, boundary_type: :user
        get urgency: :low, feature_category: :continuous_integration do
          pipelines = ::Ci::PipelinesForUserFinder
            .new(current_user, declared_params(include_missing: false))
            .execute
            .with_user_pipelines_api_associations

          params[:pagination] = 'keyset' # keyset is the only supported pagination
          pipelines = paginate_with_strategies(pipelines)

          pipelines = filter_with_logging(
            collection: pipelines,
            filter_proc: -> { ::Ci::PipelinesForUserFinder.visible_to(pipelines, current_user) },
            resource_type: 'api/pipelines'
          )

          # Register every pipeline with the BatchLoader before serialization so
          # the per-pipeline warning lookups collapse into a single query.
          pipelines.each(&:number_of_warnings)

          present pipelines, with: Entities::Ci::UserPipeline, current_user: current_user
        end
      end
    end
  end
end
