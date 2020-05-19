# frozen_string_literal: true

require 'openssl'

module Clusters
  module Kubernetes
    class ConfigureIstioIngressService
      PASSTHROUGH_RESOURCE = Kubeclient::Resource.new(
        mode: 'PASSTHROUGH'
      ).freeze

      MTLS_RESOURCE = Kubeclient::Resource.new(
        mode: 'MUTUAL',
        privateKey: '/etc/istio/ingressgateway-certs/tls.key',
        serverCertificate: '/etc/istio/ingressgateway-certs/tls.crt',
        caCertificates: '/etc/istio/ingressgateway-ca-certs/cert.pem'
      ).freeze

      def initialize(cluster:)
        @cluster = cluster
        @platform = cluster.platform
        @kubeclient = platform.kubeclient
        @knative = cluster.application_knative
      end

      def execute
        return configure_certificates if serverless_domain_cluster

        configure_passthrough
      rescue Kubeclient::HttpError => e
        knative.make_errored!(_('Kubernetes error: %{error_code}') % { error_code: e.error_code })
      rescue StandardError
        knative.make_errored!(_('Failed to update.'))
      end

      private

      attr_reader :cluster, :platform, :kubeclient, :knative

      def serverless_domain_cluster
        knative&.serverless_domain_cluster
      end

      def configure_certificates
        create_or_update_istio_cert_and_key
        set_gateway_wildcard_https(MTLS_RESOURCE)
      end

      def create_or_update_istio_cert_and_key
        name = OpenSSL::X509::Name.parse("CN=#{knative.hostname}")

        key = OpenSSL::PKey::RSA.new(2048)

        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = 0
        cert.not_before = Time.current
        cert.not_after = Time.current + 1000.years

        cert.public_key = key.public_key
        cert.subject = name
        cert.issuer = name
        cert.sign(key, OpenSSL::Digest::SHA256.new)

        serverless_domain_cluster.update!(
          key: key.to_pem,
          certificate: cert.to_pem
        )

        kubeclient.create_or_update_secret(istio_ca_certs_resource)
        kubeclient.create_or_update_secret(istio_certs_resource)
      end

      def istio_ca_certs_resource
        Gitlab::Kubernetes::GenericSecret.new(
          'istio-ingressgateway-ca-certs',
          {
            'cert.pem': Base64.strict_encode64(serverless_domain_cluster.certificate)
          },
          Clusters::Kubernetes::ISTIO_SYSTEM_NAMESPACE
        ).generate
      end

      def istio_certs_resource
        Gitlab::Kubernetes::TlsSecret.new(
          'istio-ingressgateway-certs',
          serverless_domain_cluster.certificate,
          serverless_domain_cluster.key,
          Clusters::Kubernetes::ISTIO_SYSTEM_NAMESPACE
        ).generate
      end

      def set_gateway_wildcard_https(tls_resource)
        gateway_resource = gateway
        gateway_resource.spec.servers.each do |server|
          next unless server.hosts == ['*'] && server.port.name == 'https'

          server.tls = tls_resource
        end
        kubeclient.update_gateway(gateway_resource)
      end

      def configure_passthrough
        set_gateway_wildcard_https(PASSTHROUGH_RESOURCE)
      end

      def gateway
        kubeclient.get_gateway('knative-ingress-gateway', Clusters::Kubernetes::KNATIVE_SERVING_NAMESPACE)
      end
    end
  end
end
