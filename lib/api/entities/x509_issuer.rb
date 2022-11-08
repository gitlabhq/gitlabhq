# frozen_string_literal: true

module API
  module Entities
    class X509Issuer < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :subject, documentation: { type: 'string', example: 'CN=PKI,OU=Example,O=World' }
      expose :subject_key_identifier, documentation: {
        type: 'string',
        example: 'AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB'
      }
      expose :crl_url, documentation: { type: 'string', example: 'http://example.com/pki.crl' }
    end
  end
end
