module Gitlab
  module Prometheus
    module QueryDispatch
      extend ActiveSupport::Concern

      # def environment_metrics(environment)
      #   query(environment).environment_metrics(environment)
      # end
      #
      # def deployment_metrics(deployment)
      #   query(deployment.environment).deployment_metrics(deployment)
      # end
      #
      # def additional_environment_metrics(environment)
      #   query(environment).additional_environment_metrics(environment)
      # end
      #
      # def additional_deployment_metrics(deployment)
      #   query(deployment.environment).additional_deployment_metrics(deployment)
      # end
      #
      # def matched_metrics
      #   query.matched_metrics
      # end
      #

      included do
        def query_prometheus(environment = false)
          prometheus_application(environment) || prometheus_service
          QueryingAdapter.new(prometheus_application(environment) || prometheus_service)
        end

        private

        def prometheus_application(environment = nil)
          clusters = if environment
                       # sort results by descending order based on environment_scope being longer
                       # thus more closely matching environment slug
                       project.clusters.enabled.for_environment(environment).sort_by { |c| c.environment_scope&.length }.reverse!
                     else
                       project.clusters.enabled.for_all_environments
                     end

          cluster = clusters&.detect { |cluster| cluster.application_prometheus&.installed? }
          cluster&.application_prometheus
        end
      end
    end
  end
end
