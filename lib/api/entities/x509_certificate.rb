# frozen_string_literal: true

module API
  module Entities
    class X509Certificate < Grape::Entity
      expose :id
      expose :subject
      expose :subject_key_identifier
      expose :email
      expose :serial_number
      expose :certificate_status
      expose :x509_issuer, using: 'API::Entities::X509Issuer'
    end
  end
end
