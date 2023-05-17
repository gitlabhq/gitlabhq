# frozen_string_literal: true

module Mutations
  module Metrics
    module Dashboard
      module Annotations
        class Delete < Base
          graphql_name 'DeleteAnnotation'

          authorize :admin_metrics_dashboard_annotation

          argument :id, ::Types::GlobalIDType[::Metrics::Dashboard::Annotation],
                  required: true,
                  description: 'Global ID of the annotation to delete.'

          def resolve(id:)
            raise_resource_not_available_error! if Feature.enabled?(:remove_monitor_metrics)

            annotation = authorized_find!(id: id)

            result = ::Metrics::Dashboard::Annotations::DeleteService.new(context[:current_user], annotation).execute

            errors = Array.wrap(result[:message])

            {
              errors: errors
            }
          end
        end
      end
    end
  end
end
