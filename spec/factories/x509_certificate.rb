# frozen_string_literal: true

FactoryBot.define do
  factory :x509_certificate do
    subject_key_identifier { 'BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC' }
    subject { 'CN=gitlab@example.org,OU=Example,O=World' }

    email { 'gitlab@example.org' }
    serial_number { 278969561018901340486471282831158785578 }
    x509_issuer
    certificate_status { :good }
  end
end
