# frozen_string_literal: true

module Clusters
  module Concerns
    module ApplicationData
      def repository
        nil
      end

      def values
        File.read(chart_values_file)
      end

      def files
        @files ||= { 'values.yaml': values }
      end

      private

      def certificate_files
        {
          'ca.pem': ca_cert,
          'cert.pem': helm_cert.cert_string,
          'key.pem': helm_cert.key_string
        }
      end

      def ca_cert
        cluster.application_helm.ca_cert
      end

      def helm_cert
        @helm_cert ||= cluster.application_helm.issue_client_cert
      end

      def chart_values_file
        "#{Rails.root}/vendor/#{name}/values.yaml"
      end
    end
  end
end
