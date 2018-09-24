# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_occurrence_identifier, class: Vulnerabilities::OccurrenceIdentifier do
    occurrence factory: :vulnerabilities_occurrence
    identifier factory: :vulnerabilities_identifier
  end
end
