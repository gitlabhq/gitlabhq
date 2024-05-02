# frozen_string_literal: true

module Resolvers
  class DeploymentsResolver < BaseResolver
    argument :statuses, [Types::DeploymentStatusEnum],
      description: 'Statuses of the deployments.',
      required: false,
      as: :status

    argument :order_by, Types::DeploymentsOrderByInputType,
      description: 'Order by a specified field.',
      required: false

    type Types::DeploymentType, null: true

    alias_method :environment, :object

    def resolve(**args)
      return unless environment.present? && environment.is_a?(::Environment)

      args = transform_args_for_finder(**args)

      # GraphQL BatchLoader shouldn't be used here because pagination query will be inefficient
      # that fetches thousands of rows before limiting and offsetting.
      DeploymentsFinder.new(environment: environment.id, **args).execute
    end

    private

    def transform_args_for_finder(**args)
      if (order_by = args.delete(:order_by))
        order_by = order_by.to_h.map { |k, v| { order_by: k.to_s, sort: v } }.first
        args.merge!(order_by)
      end

      args
    end
  end
end
