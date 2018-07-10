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
          return {} unless cluster.application_helm.has_ssl?
          client_cert = cluster.application_helm.issue_cert

          {
            CA_CERT: cluster.application_helm.ca_cert,
            HELM_CERT: client_cert.cert_string,
            HELM_KEY: client_cert.key_string
          }
        end
      end
    end
  end
end
