# frozen_string_literal: true

module Resolvers
  module Admin
    module Analytics
      module UsageTrends
        class MeasurementsResolver < BaseResolver
          include Gitlab::Graphql::Authorize::AuthorizeResource

          type Types::Admin::Analytics::UsageTrends::MeasurementType, null: true

          argument :identifier, Types::Admin::Analytics::UsageTrends::MeasurementIdentifierEnum,
                    required: true,
                    description: 'The type of measurement/statistics to retrieve.'

          argument :recorded_after, Types::TimeType,
                    required: false,
                    description: 'Measurement recorded after this date.'

          argument :recorded_before, Types::TimeType,
                    required: false,
                    description: 'Measurement recorded before this date.'

          def resolve(identifier:, recorded_before: nil, recorded_after: nil)
            authorize!

            ::Analytics::UsageTrends::Measurement
              .recorded_after(recorded_after)
              .recorded_before(recorded_before)
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
