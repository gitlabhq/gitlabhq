module Clusters
  module Concerns
    module ApplicationData
      extend ActiveSupport::Concern

      included do
        def repository
          nil
        end

        def values
          File.read(chart_values_file)
        end

        private

        def chart_values_file
          "#{Rails.root}/vendor/#{name}/values.yaml"
        end

        def extra_env
          {
            CA_CERT: cluster.application_helm.ca_cert,
            HELM_CERT: cluster.application_helm.client_cert,
            HELM_KEY: cluster.application_helm.client_key
          }
        end
      end
    end
  end
end
