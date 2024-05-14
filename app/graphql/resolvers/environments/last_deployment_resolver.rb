# frozen_string_literal: true

module Resolvers
  module Environments
    class LastDeploymentResolver < BaseResolver
      argument :status,
        Types::DeploymentStatusEnum,
        required: true,
        description: 'Status of the Deployment.'

      type Types::DeploymentType, null: true

      def resolve(status:)
        return unless object.present? && object.is_a?(::Environment)

        validate!(status)

        find_last_deployment(status)
      end

      private

      def find_last_deployment(status)
        BatchLoader::GraphQL.for(object).batch(key: status) do |environments, loader, args|
          association_name = "last_#{args[:key]}_deployment".to_sym

          Preloaders::Environments::DeploymentPreloader.new(environments)
            .execute_with_union(association_name, {})

          environments.each do |environment|
            loader.call(environment, environment.public_send(association_name)) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end

      def validate!(status)
        unless Deployment::FINISHED_STATUSES.include?(status.to_sym) ||
            Deployment::UPCOMING_STATUSES.include?(status.to_sym)
          raise Gitlab::Graphql::Errors::ArgumentError, "\"#{status}\" status is not supported."
        end
      end
    end
  end
end
