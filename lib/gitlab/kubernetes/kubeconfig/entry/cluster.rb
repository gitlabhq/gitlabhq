# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Kubeconfig
      module Entry
        class Cluster
          attr_reader :name

          def initialize(name:, url:, ca_pem: nil)
            @name = name
            @url = url
            @ca_pem = ca_pem
          end

          def to_h
            {
              name: name,
              cluster: cluster
            }
          end

          private

          attr_reader :url, :ca_pem

          def cluster
            {
              server: url,
              'certificate-authority-data': certificate_authority_data
            }.compact
          end

          def certificate_authority_data
            return unless ca_pem.present?

            Base64.strict_encode64(ca_pem)
          end
        end
      end
    end
  end
end
