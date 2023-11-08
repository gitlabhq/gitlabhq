# frozen_string_literal: true

module Resolvers
  module DataTransfer
    class ProjectDataTransferResolver < BaseResolver
      include DataTransferArguments
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorizes_object!
      authorize :read_usage_quotas

      type Types::DataTransfer::ProjectDataTransferType, null: false

      alias_method :project, :object

      def resolve(**args)
        return { egress_nodes: [] } unless Feature.enabled?(:data_transfer_monitoring, project.group)

        results = ::DataTransfer::ProjectDataTransferFinder.new(
          project: project,
          from: args[:from],
          to: args[:to],
          user: current_user
        ).execute

        { egress_nodes: results }
      end
    end
  end
end
