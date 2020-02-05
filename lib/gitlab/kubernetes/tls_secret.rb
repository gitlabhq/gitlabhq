# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class TlsSecret
      attr_reader :name, :cert, :key, :namespace_name

      def initialize(name, cert, key, namespace_name)
        @name = name
        @cert = cert
        @key = key
        @namespace_name = namespace_name
      end

      def generate
        ::Kubeclient::Resource.new(
          type: tls_secret_type,
          metadata: metadata,
          data: data
        )
      end

      private

      def tls_secret_type
        'kubernetes.io/tls'
      end

      def metadata
        {
          name: name,
          namespace: namespace_name
        }
      end

      def data
        {
          'tls.crt': Base64.strict_encode64(cert),
          'tls.key': Base64.strict_encode64(key)
        }
      end
    end
  end
end
