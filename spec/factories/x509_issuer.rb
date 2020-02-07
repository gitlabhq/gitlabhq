# frozen_string_literal: true

FactoryBot.define do
  factory :x509_issuer do
    subject_key_identifier { 'AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB' }
    subject { 'CN=PKI,OU=Example,O=World' }

    crl_url { 'http://example.com/pki.crl' }
  end
end
