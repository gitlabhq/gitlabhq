# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_artifact, class: 'Ci::JobArtifact' do
    job factory: :ci_build
    file_type { :archive }
    file_format { :zip }

    trait :expired do
      expire_at { Time.current.yesterday.change(minute: 9) }
    end

    trait :locked do
      locked { Ci::JobArtifact.lockeds[:artifacts_locked] }
    end

    trait :remote_store do
      file_store { JobArtifactUploader::Store::REMOTE }
    end

    after :build do |artifact|
      artifact.project ||= artifact.job.project

      artifact.job&.valid?
    end

    trait :raw do
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'text/plain')
      end
    end

    trait :zip do
      file_format { :zip }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
      end
    end

    trait :gzip do
      file_format { :gzip }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'), 'application/x-gzip')
      end
    end

    trait :archive do
      file_type { :archive }
      file_format { :zip }

      transient do
        file { fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip') }
      end

      after(:build) do |artifact, evaluator|
        artifact.file = evaluator.file
      end
    end

    trait :legacy_archive do
      archive

      file_location { :legacy_path }
    end

    trait :metadata do
      file_type { :metadata }
      file_format { :gzip }

      transient do
        file { fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'), 'application/x-gzip') }
      end

      after(:build) do |artifact, evaluator|
        artifact.file = evaluator.file
      end
    end

    trait :trace do
      file_type { :trace }
      file_format { :raw }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'text/plain')
      end
    end

    trait :unarchived_trace_artifact do
      file_type { :trace }
      file_format { :raw }

      after(:build) do |artifact, evaluator|
        file = double('file', path: '/path/to/job.log')
        artifact.file = file
        allow(artifact.file).to receive(:file).and_return(CarrierWave::SanitizedFile.new(file))
      end
    end

    trait :junit do
      file_type { :junit }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/junit/junit.xml.gz'), 'application/x-gzip')
      end
    end

    trait :junit_with_attachment do
      file_type { :junit }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/junit/junit_with_attachment.xml.gz'), 'application/x-gzip')
      end
    end

    trait :junit_with_duplicate_failed_test_names do
      file_type { :junit }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/junit/junit_with_duplicate_failed_test_names.xml.gz'), 'application/x-gzip')
      end
    end

    trait :junit_with_ant do
      file_type { :junit }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/junit/junit_ant.xml.gz'), 'application/x-gzip')
      end
    end

    trait :junit_with_three_testsuites do
      file_type { :junit }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/junit/junit_with_three_testsuites.xml.gz'), 'application/x-gzip')
      end
    end

    trait :junit_with_corrupted_data do
      file_type { :junit }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/junit/junit_with_corrupted_data.xml.gz'), 'application/x-gzip')
      end
    end

    trait :junit_with_three_failures do
      file_type { :junit }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/junit/junit_with_three_failures.xml.gz'), 'application/x-gzip')
      end
    end

    trait :private do
      accessibility { 'private' }
    end

    trait :public do
      accessibility { 'public' }
    end

    trait :none do
      accessibility { 'none' }
    end

    trait :accessibility do
      file_type { :accessibility }
      file_format { :raw }

      after(:build) do |artifact, _evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/accessibility/pa11y_with_errors.json'), 'application/json')
      end
    end

    trait :accessibility_with_invalid_url do
      file_type { :accessibility }
      file_format { :raw }

      after(:build) do |artifact, _evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/accessibility/pa11y_with_invalid_url.json'), 'application/json')
      end
    end

    trait :accessibility_without_errors do
      file_type { :accessibility }
      file_format { :raw }

      after(:build) do |artifact, _evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/accessibility/pa11y_without_errors.json'), 'application/json')
      end
    end

    trait :cobertura do
      file_type { :cobertura }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/cobertura/coverage.xml.gz'), 'application/x-gzip')
      end
    end

    trait :jacoco do
      file_type { :jacoco }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/jacoco/coverage.xml.gz'), 'application/x-gzip')
      end
    end

    trait :terraform do
      file_type { :terraform }
      file_format { :raw }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/terraform/tfplan.json'), 'application/json')
      end
    end

    trait :terraform_with_corrupted_data do
      file_type { :terraform }
      file_format { :raw }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/terraform/tfplan_with_corrupted_data.json'), 'application/json')
      end
    end

    trait :coverage_gocov_xml do
      file_type { :cobertura }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/cobertura/coverage_gocov_xml.xml.gz'), 'application/x-gzip')
      end
    end

    trait :coverage_with_paths_not_relative_to_project_root do
      file_type { :cobertura }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/cobertura/coverage_with_paths_not_relative_to_project_root.xml.gz'), 'application/x-gzip')
      end
    end

    trait :coverage_with_corrupted_data do
      file_type { :cobertura }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/cobertura/coverage_with_corrupted_data.xml.gz'), 'application/x-gzip')
      end
    end

    trait :codequality do
      file_type { :codequality }
      file_format { :raw }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/codequality/codeclimate.json'), 'application/json')
      end
    end

    trait :codequality_without_errors do
      file_type { :codequality }
      file_format { :raw }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/codequality/codeclimate_without_errors.json'), 'application/json')
      end
    end

    trait :sast do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-sast-report.json'), 'application/json')
      end
    end

    trait :sast_minimal do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-sast-report-minimal.json'), 'application/json')
      end
    end

    # Bandit reports are correctly de-duplicated when ran in the same pipeline
    # as a corresponding semgrep report.
    # This report does not include signature tracking.
    trait :sast_bandit do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-sast-report-bandit.json'), 'application/json')
      end
    end

    # Equivalent Semgrep report for :sast_bandit report.
    # This report includes signature tracking.
    trait :sast_semgrep_for_bandit do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-sast-report-semgrep-for-bandit.json'), 'application/json')
      end
    end

    # Gosec reports are not correctly de-duplicated when ran in the same pipeline
    # as a corresponding semgrep report.
    # This report includes signature tracking.
    trait :sast_gosec do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-sast-report-gosec.json'), 'application/json')
      end
    end

    # Equivalent Semgrep report for :sast_gosec report.
    # This report includes signature tracking.
    trait :sast_semgrep_for_gosec do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-sast-report-semgrep-for-gosec.json'), 'application/json')
      end
    end

    # Equivalent Semgrep report for combined :sast_bandit and :sast_gosec reports.
    # This report includes signature tracking.
    trait :sast_semgrep_for_multiple_findings do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-sast-report-semgrep-for-multiple-findings.json'), 'application/json')
      end
    end

    trait :common_security_report do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-common-scanning-report.json'), 'application/json')
      end
    end

    trait :common_security_report_without_top_level_scanner do
      common_security_report

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-common-scanning-report-without-top-level-scanner.json'), 'application/json')
      end
    end

    trait :common_security_report_with_blank_names do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-common-scanning-report-names.json'), 'application/json')
      end
    end

    trait :common_security_report_with_unicode_null_character do
      common_security_report

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-common-scanning-report-with-unicode-null-character.json'), 'application/json')
      end
    end

    trait :sast_with_corrupted_data do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :sast_feature_branch do
      file_format { :raw }
      file_type { :sast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/feature-branch/gl-sast-report.json'), 'application/json')
      end
    end

    trait :secret_detection_feature_branch do
      file_format { :raw }
      file_type { :secret_detection }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/feature-branch/gl-secret-detection-report.json'), 'application/json')
      end
    end

    trait :sast_with_missing_scanner do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-sast-missing-scanner.json'), 'application/json')
      end
    end

    trait :secret_detection do
      file_type { :secret_detection }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security_reports/master/gl-secret-detection-report.json'), 'application/json')
      end
    end

    trait :lsif do
      file_type { :lsif }
      file_format { :zip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/lsif.json.zip'), 'application/zip')
      end
    end

    trait :dotenv do
      file_type { :dotenv }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/build.env.gz'), 'application/x-gzip')
      end
    end

    trait :correct_checksum do
      after(:build) do |artifact, evaluator|
        artifact.file_sha256 = Digest::SHA256.file(artifact.file.path).hexdigest
      end
    end

    trait :annotations do
      file_type { :annotations }
      file_format { :gzip }

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/gl-annotations.json.gz'), 'application/x-gzip')
      end
    end
  end
end
