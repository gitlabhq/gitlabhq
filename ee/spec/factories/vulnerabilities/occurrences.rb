# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_occurrence, class: Vulnerabilities::Occurrence do
    name 'Cipher with no integrity'
    project
    pipeline factory: :ci_pipeline
    ref 'master'
    uuid 'a7342ca9-494e-457f-88e7-e65e145cc392'
    project_fingerprint '4e5b6966dd100170b4b1ad599c7058cce91b57b4'
    primary_identifier_fingerprint '4e5b6966dd100170b4b1ad599c7058cce91b57b4'
    location_fingerprint '4e5b6966dd100170b4b1ad599c7058cce91b57b4'
    report_type :sast
    severity :high
    confidence :medium
    scanner factory: :vulnerabilities_scanner
    metadata_version 'sast:1.0'
    raw_metadata 'raw_metadata'
  end
end
