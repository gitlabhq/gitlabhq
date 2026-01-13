# frozen_string_literal: true

module API
  module Entities
    class X509Signature < Grape::Entity
      expose :verification_status, documentation: { type: 'String', example: 'unverified' }
      expose :x509_certificate, using: ::API::Entities::X509Certificate
    end
  end
end
