# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_finding, class: '::Gitlab::Ci::Reports::Security::Finding' do
    confidence { :medium }
    identifiers { Array.new(1) { association(:ci_reports_security_identifier) } }
    location factory: :ci_reports_security_locations_sast
    evidence factory: :ci_reports_security_evidence
    metadata_version { 'sast:1.0' }
    name { 'Cipher with no integrity' }
    report_type { :sast }
    cvss { [{ vendor: "GitLab", vector: "CVSS:3.1/AV:N/AC:L/PR:H/UI:N/S:U/C:L/I:L/A:N" }] }
    original_data do
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
        ],
        raw_source_code_extract: 'AES/ECB/NoPadding',
        evidence: {
          summary: 'Credit card detected',
          request: {
            headers: [{ name: 'Accept', value: '*/*' }],
            method: 'GET',
            url: 'http://goat:8080/WebGoat/logout',
            body: nil
          },
          response: {
            headers: [{ name: 'Content-Length', value: '0' }],
            reason_phrase: 'OK',
            status_code: 200,
            body: nil
          },
          source: {
            id: 'assert:Response Body Analysis',
            name: 'Response Body Analysis',
            url: 'htpp://hostname/documentation'
          },
          supporting_messages: [
            {
              name: 'Origional',
              request: {
                headers: [{ name: 'Accept', value: '*/*' }],
                method: 'GET',
                url: 'http://goat:8080/WebGoat/logout',
                body: ''
              }
            },
            {
              name: 'Recorded',
              request: {
                headers: [{ name: 'Accept', value: '*/*' }],
                method: 'GET',
                url: 'http://goat:8080/WebGoat/logout',
                body: ''
              },
              response: {
                headers: [{ name: 'Content-Length', value: '0' }],
                reason_phrase: 'OK',
                status_code: 200,
                body: ''
              }
            }
          ]
        }
      }.deep_stringify_keys
    end
    scanner factory: :ci_reports_security_scanner
    severity { :high }
    scan factory: :ci_reports_security_scan
    sequence(:uuid) do |n|
      ::Security::VulnerabilityUUID.generate(
        report_type: report_type,
        primary_identifier_fingerprint: identifiers.first&.fingerprint,
        location_fingerprint: location.fingerprint,
        project_id: n
      )
    end
    vulnerability_finding_signatures_enabled { false }

    skip_create

    trait :dynamic do
      location { association(:ci_reports_security_locations_sast, :dynamic) }
    end

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Finding.new(**attributes)
    end
  end
end
