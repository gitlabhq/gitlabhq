# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerJobsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead

      type ::Types::Ci::JobType.connection_type, null: true
      authorize :read_builds
      authorizes_object!
      extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

      argument :statuses, [::Types::Ci::JobStatusEnum],
               required: false,
               description: 'Filter jobs by status.'

      alias_method :runner, :object

      def resolve_with_lookahead(statuses: nil)
        jobs = ::Ci::JobsFinder.new(current_user: current_user, runner: runner, params: { scope: statuses }).execute

        apply_lookahead(jobs)
      end

      private

      def preloads
        {
          previous_stage_jobs_or_needs: [:needs, :pipeline],
          artifacts: [:job_artifacts],
          pipeline: [:user],
          project: [{ project: [:route, { namespace: [:route] }] }],
          detailed_status: [
            :metadata,
            { pipeline: [:merge_request] },
            { project: [:route, { namespace: :route }] }
          ],
          commit_path: [:pipeline, { project: { namespace: [:route] } }],
          ref_path: [{ project: [:route, { namespace: [:route] }] }],
          browse_artifacts_path: [{ project: { namespace: [:route] } }],
          play_path: [{ project: { namespace: [:route] } }],
          web_path: [{ project: { namespace: [:route] } }],
          short_sha: [:pipeline],
          tags: [:tags]
        }
      end
    end
  end
end
