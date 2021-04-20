# frozen_string_literal: true

FactoryBot.define do
  factory :codequality_degradation_1, class: Hash do
    skip_create

    initialize_with do
      {
        "categories": [
          "Complexity"
        ],
        "check_name": "argument_count",
        "content": {
          "body": ""
        },
        "description": "Avoid parameter lists longer than 5 parameters. [12/5]",
        "fingerprint": "15cdb5c53afd42bc22f8ca366a08d547",
        "location": {
          "path": "file_a.rb",
          "lines": {
            "begin": 10,
            "end": 10
          }
        },
        "other_locations": [],
        "remediation_points": 900000,
        "severity": "major",
        "type": "issue",
        "engine_name": "structure"
      }.with_indifferent_access
    end
  end

  factory :codequality_degradation_2, class: Hash do
    skip_create

    initialize_with do
      {
        "categories": [
          "Complexity"
        ],
        "check_name": "argument_count",
        "content": {
          "body": ""
        },
        "description": "Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.",
        "fingerprint": "f3bdc1e8c102ba5fbd9e7f6cda51c95e",
        "location": {
          "path": "file_a.rb",
          "lines": {
            "begin": 10,
            "end": 10
          }
        },
        "other_locations": [],
        "remediation_points": 900000,
        "severity": "major",
        "type": "issue",
        "engine_name": "structure"
      }.with_indifferent_access
    end
  end

  factory :codequality_degradation_3, class: Hash do
    skip_create

    initialize_with do
      {
        "type": "Issue",
        "check_name": "Rubocop/Metrics/ParameterLists",
        "description": "Avoid parameter lists longer than 5 parameters. [12/5]",
        "categories": [
          "Complexity"
        ],
        "remediation_points": 550000,
        "location": {
          "path": "file_b.rb",
          "positions": {
            "begin": {
              "column": 14,
              "line": 10
            },
            "end": {
              "column": 39,
              "line": 10
            }
          }
        },
        "content": {
          "body": "This cop checks for methods with too many parameters.\nThe maximum number of parameters is configurable.\nKeyword arguments can optionally be excluded from the total count."
        },
        "engine_name": "rubocop",
        "fingerprint": "ab5f8b935886b942d621399f5a2ca16e",
        "severity": "minor"
      }.with_indifferent_access
    end
  end

  # TODO: Use this in all other specs and remove the previous numbered factories
  # https://gitlab.com/gitlab-org/gitlab/-/issues/325886
  factory :codequality_degradation, class: Hash do
    skip_create

    # Feel free to add in more configurable properties here
    # as the need arises
    fingerprint { SecureRandom.hex }
    severity { "major" }

    Gitlab::Ci::Reports::CodequalityReports::SEVERITY_PRIORITIES.keys.each do |s|
      trait s.to_sym do
        severity { s }
      end
    end

    initialize_with do
      {
        "categories": [
          "Complexity"
        ],
        "check_name": "argument_count",
        "content": {
          "body": ""
        },
        "description": "Avoid parameter lists longer than 5 parameters. [12/5]",
        "fingerprint": fingerprint,
        "location": {
          "path": "file_a.rb",
          "lines": {
            "begin": 10,
            "end": 10
          }
        },
        "other_locations": [],
        "remediation_points": 900000,
        "severity": severity,
        "type": "issue",
        "engine_name": "structure"
      }.with_indifferent_access
    end
  end
end
