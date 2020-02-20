# frozen_string_literal: true

module API
  module Entities
    class PagesDomainCertificateExpiration < Grape::Entity
      expose :expired?, as: :expired
      expose :expiration
    end
  end
end
