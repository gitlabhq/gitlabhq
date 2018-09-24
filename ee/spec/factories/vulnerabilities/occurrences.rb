# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_occurrence, class: Vulnerabilities::Occurrence do
    name 'Cipher with no integrity'
    project
    pipeline factory: :ci_pipeline
    ref 'master'
    first_seen_in_commit_sha '52d084cede3db8fafcd6b8ae382ddf1970da3b7f'
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
