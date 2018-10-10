# frozen_string_literal: true

FactoryBot.define do
  sequence :vulnerability_occurrence_uuid do |n|
    Digest::SHA1.hexdigest("uuid-#{n}")[0..35]
  end

  factory :vulnerabilities_occurrence, class: Vulnerabilities::Occurrence do
    name 'Cipher with no integrity'
    project
    pipeline factory: :ci_pipeline
    ref 'master'
    sequence(:uuid) { generate(:vulnerability_occurrence_uuid)  }
    project_fingerprint { generate(:project_fingerprint) }
    primary_identifier_fingerprint '4e5b6966dd100170b4b1ad599c7058cce91b57b4'
    location_fingerprint '4e5b6966dd100170b4b1ad599c7058cce91b57b4'
    report_type :sast
    severity :high
    confidence :medium
    scanner factory: :vulnerabilities_scanner
    metadata_version 'sast:1.0'
    raw_metadata do
      {
        description: "The cipher does not provide data integrity update 1",
        solution: "GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.",
        location: {
          file: "maven/src/main/java/com/gitlab/security_products/tests/App.java",
          start_line: 29,
          end_line: 29,
          class: "com.gitlab.security_products.tests.App",
          method: "insecureCypher"
        },
        links: [
          {
            name: "Cipher does not check for integrity first?",
            url: "https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first"
          }
        ]
      }.to_json
    end
  end
end
