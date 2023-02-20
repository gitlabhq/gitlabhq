# frozen_string_literal: true

module Types
  # rubocop:disable Graphql/AuthorizeTypes
  # TODO: This type should be removed when Work Items become generally available.
  # This mechanism is introduced temporarily to make the client implementation easier during this transition.
  class WorkItemIdType < GlobalIDType
    graphql_name 'WorkItemID'
    description <<~DESC
      A `WorkItemID` is a global ID. It is encoded as a string.

      An example `WorkItemID` is: `"gid://gitlab/WorkItem/1"`.

      While we transition from Issues into Work Items this type will temporarily support
      `IssueID` like: `"gid://gitlab/Issue/1"`. This behavior will be removed without notice in the future.
    DESC

    class << self
      def coerce_result(gid, ctx)
        global_id = ::Gitlab::GlobalId.as_global_id(gid, model_name: 'WorkItem')

        raise GraphQL::CoercionError, "Expected a WorkItem ID, got #{global_id}" unless suitable?(global_id)

        # Always return a WorkItemID even if an Issue is returned by a resolver
        work_item_gid(global_id).to_s
      end

      def coerce_input(string, ctx)
        gid = super
        return if gid.nil?
        # Always return a WorkItemID even if an Issue Global ID is provided as input
        return work_item_gid(gid) if suitable?(gid)

        raise GraphQL::CoercionError, "#{string.inspect} does not represent an instance of WorkItem"
      end

      def suitable?(gid)
        return false if gid&.model_name&.safe_constantize.blank?

        # Using === operation doesn't work for model classes.
        # See https://github.com/rails/rails/blob/v6.1.6.1/activerecord/lib/active_record/core.rb#L452
        # rubocop:disable Performance/RedundantEqualityComparisonBlock
        [::WorkItem, ::Issue].any? { |model_class| gid.model_class == model_class }
        # rubocop:enable Performance/RedundantEqualityComparisonBlock
      end

      private

      def work_item_gid(gid)
        GlobalID.new(::Gitlab::GlobalId.build(model_name: 'WorkItem', id: gid.model_id))
      end
    end
  end
  # rubocop:enable Graphql/AuthorizeTypes
end
