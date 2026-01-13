# frozen_string_literal: true

module API
  module Entities
    class X509Issuer < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :subject, documentation: { type: 'String', example: 'CN=PKI,OU=Example,O=World' }
      expose :subject_key_identifier, documentation: {
        type: 'String',
        example: 'AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB'
      }
      expose :crl_url, documentation: { type: 'String', example: 'http://example.com/pki.crl' }
    end
  end
end
