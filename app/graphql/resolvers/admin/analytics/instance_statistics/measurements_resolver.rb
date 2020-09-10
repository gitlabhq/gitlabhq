# frozen_string_literal: true

module Resolvers
  module Admin
    module Analytics
      module InstanceStatistics
        class MeasurementsResolver < BaseResolver
          include Gitlab::Graphql::Authorize::AuthorizeResource

          type Types::Admin::Analytics::InstanceStatistics::MeasurementType, null: true

          argument :identifier, Types::Admin::Analytics::InstanceStatistics::MeasurementIdentifierEnum,
                    required: true,
                    description: 'The type of measurement/statistics to retrieve'

          def resolve(identifier:)
            authorize!

            ::Analytics::InstanceStatistics::Measurement
              .with_identifier(identifier)
              .order_by_latest
          end

          private

          def authorize!
            admin? || raise_resource_not_available_error!
          end

          def admin?
            context[:current_user].present? && context[:current_user].admin?
          end
        end
      end
    end
  end
end
