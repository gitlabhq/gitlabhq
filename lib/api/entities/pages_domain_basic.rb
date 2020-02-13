# frozen_string_literal: true

module API
  module Entities
    class PagesDomainBasic < Grape::Entity
      expose :domain
      expose :url
      expose :project_id
      expose :verified?, as: :verified
      expose :verification_code, as: :verification_code
      expose :enabled_until
      expose :auto_ssl_enabled

      expose :certificate,
        as: :certificate_expiration,
        if: ->(pages_domain, _) { pages_domain.certificate? },
        using: Entities::PagesDomainCertificateExpiration do |pages_domain|
        pages_domain
      end
    end
  end
end
