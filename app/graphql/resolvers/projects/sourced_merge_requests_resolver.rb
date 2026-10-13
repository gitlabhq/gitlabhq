# frozen_string_literal: true

module Resolvers
  module Projects
    class SourcedMergeRequestsResolver < BaseResolver
      prepend ::MergeRequests::LookAheadPreloads

      MAX_SOURCE_BRANCHES = 100

      type Types::MergeRequestType.connection_type, null: true

      alias_method :project, :object

      # Preload what MergeRequestPolicy needs on each (possibly distinct)
      # target project, so per-node authorization does not N+1.
      before_connection_authorization do |merge_requests, current_user|
        ActiveRecord::Associations::Preloader.new(
          records: merge_requests,
          associations: { target_project: [:project_feature, :project_namespace, :group, { namespace: :owner }] }
        ).call

        # The max access level is a request-store-cached aggregate, not an
        # association, so it needs its own preloader per target project.
        ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(
          merge_requests.map(&:target_project).uniq, current_user
        ).execute
      end

      argument :source_branches, [GraphQL::Types::String],
        required: true,
        validates: { length: { maximum: MAX_SOURCE_BRANCHES } },
        description: "Array of source branch names (maximum is #{MAX_SOURCE_BRANCHES}). " \
          'All resolved merge requests will have one of these branches as their source.'

      argument :state, ::Types::MergeRequestStateEnum,
        required: false,
        description: 'Merge request state. If provided, all resolved merge requests will have the state.'

      # An empty sourceBranches array satisfies required: true but would drop
      # the branch predicate in the finder, producing an unindexed query.
      def ready?(**args)
        return [false, MergeRequest.none] if no_results_possible?(args)

        super
      end

      def resolve_with_lookahead(source_branches:, state: nil)
        merge_requests = ::MergeRequestsFinder.new(
          current_user,
          source_project_id: project.id,
          source_branch: source_branches,
          state: state
        ).execute

        apply_lookahead(merge_requests.order_id_desc)
      end

      private

      def no_results_possible?(args)
        args[:source_branches].empty?
      end
    end
  end
end
