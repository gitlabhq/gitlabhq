# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_scanner, class: Vulnerabilities::Scanner do
    external_id 'find_sec_bugs'
    name 'Find Security Bugs'
    project
  end
end
