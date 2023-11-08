# frozen_string_literal: true

module Resolvers
  module DataTransfer
    class GroupDataTransferResolver < BaseResolver
      include DataTransferArguments
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorizes_object!
      authorize :read_usage_quotas

      type Types::DataTransfer::GroupDataTransferType, null: false

      alias_method :group, :object

      def resolve(**args)
        return { egress_nodes: [] } unless Feature.enabled?(:data_transfer_monitoring, group)

        results = ::DataTransfer::GroupDataTransferFinder.new(
          group: group,
          from: args[:from],
          to: args[:to],
          user: current_user
        ).execute.map(&:attributes)

        { egress_nodes: results.to_a }
      end
    end
  end
end
