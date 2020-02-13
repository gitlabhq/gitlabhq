# frozen_string_literal: true

module API
  module Entities
    class PagesDomain < Grape::Entity
      expose :domain
      expose :url
      expose :verified?, as: :verified
      expose :verification_code, as: :verification_code
      expose :enabled_until
      expose :auto_ssl_enabled

      expose :certificate,
        if: ->(pages_domain, _) { pages_domain.certificate? },
        using: Entities::PagesDomainCertificate do |pages_domain|
        pages_domain
      end
    end
  end
end
