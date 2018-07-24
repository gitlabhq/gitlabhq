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

        def files
          @files ||= begin
            files = { 'values.yaml': values }
            if cluster.application_helm.has_ssl?
              ca_cert = cluster.application_helm.ca_cert
              helm_cert = cluster.application_helm.issue_cert
              files.merge!({
                'ca.pem': ca_cert,
                'cert.pem': helm_cert.cert_string,
                'key.pem': helm_cert.key_string
              })
            end

            files
          end
        end

        private

        def chart_values_file
          "#{Rails.root}/vendor/#{name}/values.yaml"
        end
      end
    end
  end
end
