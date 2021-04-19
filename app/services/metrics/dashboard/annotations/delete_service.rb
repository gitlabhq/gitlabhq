# frozen_string_literal: true

# Delete Metrics::Dashboard::Annotation entry
module Metrics
  module Dashboard
    module Annotations
      class DeleteService < ::BaseService
        include Stepable

        steps :authorize_action,
              :delete

        def initialize(user, annotation)
          @user = user
          @annotation = annotation
        end

        def execute
          execute_steps
        end

        private

        attr_reader :user, :annotation

        def authorize_action(_options)
          if Ability.allowed?(user, :delete_metrics_dashboard_annotation, annotation)
            success
          else
            error(s_('Metrics::Dashboard::Annotation|You are not authorized to delete this annotation'))
          end
        end

        def delete(_options)
          if annotation.destroy
            success
          else
            error(s_('Metrics::Dashboard::Annotation|Annotation has not been deleted'))
          end
        end
      end
    end
  end
end
