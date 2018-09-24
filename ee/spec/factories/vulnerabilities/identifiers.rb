# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_identifier, class: Vulnerabilities::Identifier do
    external_type 'CVE'
    external_id 'CVE-2018-1234'
    fingerprint '52d084cede3db8fafcd6b8ae382ddf1970da3b7f'
    name 'CVE-2018-1234'
    url 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234'
    project
  end
end
