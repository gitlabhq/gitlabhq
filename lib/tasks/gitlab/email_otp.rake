# frozen_string_literal: true

namespace :gitlab do
  namespace :email_otp do
    desc <<~DESC
      Set Email OTP enrollment dates for users in bulk.
      ENV:
        DRY_RUN=true (default)
        ENROL_AT=<datetime>
        EXISTING_ENROL_AT=<datetime>
        BATCH_SIZE=1000
        BATCH_SLEEP=0.1

      Use EXISTING_ENROL_AT to target an existing cohort for rollback or shifting.
      This is best used when many users share the exact same enrolment
      date.

      ENROL_AT: <date> → enroll all users who are active, human, have a password, and no MFA.
      ENROL_AT: <new_date>, EXISTING_ENROL_AT: <old_date> → shift a cohort
      ENROL_AT: nil, EXISTING_ENROL_AT: <old_date> → revert a cohort to unenrolled
    DESC
    task enrol: :environment do
      args = {}

      args[:dry_run] = !(ENV.fetch('DRY_RUN', 'true').casecmp('false') == 0)
      args[:enrol_at] = DateTime.parse(ENV['ENROL_AT']).utc if ENV['ENROL_AT'].present?
      args[:existing_enrol_at] = DateTime.parse(ENV['EXISTING_ENROL_AT']).utc if ENV['EXISTING_ENROL_AT'].present?
      args[:batch_size] = ENV['BATCH_SIZE'].to_i if ENV['BATCH_SIZE'].present?
      args[:batch_sleep] = ENV['BATCH_SLEEP'].to_f if ENV['BATCH_SLEEP'].present?

      Tasks::Gitlab::EmailOtp::ManageEnrollment.new(**args).enrol
    end

    desc 'Enable mandatory Email OTP enforcement via instance setting'
    task enforce: :environment do
      Tasks::Gitlab::EmailOtp::ManageEnrollment.new.enforce
    end

    desc 'Disable mandatory Email OTP enforcement via instance setting'
    task unenforce: :environment do
      Tasks::Gitlab::EmailOtp::ManageEnrollment.new.unenforce
    end
  end
end
