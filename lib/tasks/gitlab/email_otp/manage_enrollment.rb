# frozen_string_literal: true

require 'tty-prompt'

module Tasks
  module Gitlab
    module EmailOtp
      class ManageEnrollment
        BATCH_SIZE = 1000
        # BATCH_SLEEP can be increased if replication lag becomes an issue.
        # This script is safe to interrupt. Re-run to resume.
        # See https://docs.gitlab.com/administration/postgresql/replication_and_failover/#check-replication-status
        BATCH_SLEEP = 0.1

        def initialize(
          dry_run: true,
          enrol_at: nil,
          existing_enrol_at: nil,
          batch_size: BATCH_SIZE,
          batch_sleep: BATCH_SLEEP)
          @dry_run = dry_run
          @enrol_at = enrol_at
          @existing_enrol_at = existing_enrol_at
          @batch_size = batch_size
          @batch_sleep = @dry_run ? 0 : batch_sleep
        end

        # Set an Email OTP enrollment date for all relevant users who
        # do not yet have one set, or shift/revert an existing cohort.
        # Relevant: human, active, with a password, and no MFA.
        def enrol
          if !@dry_run && @enrol_at.nil? && @existing_enrol_at.nil?
            raise ArgumentError,
              "ENROL_AT is required when DRY_RUN=false and EXISTING_ENROL_AT is not set"
          end

          confirm_settings

          log("Enrolling users...")

          total_updated = 0
          batch_num = 0

          # Performance strategy:
          # 1. Use fully-indexed outer loop (User.active.human) with each_batch (https://docs.gitlab.com/development/database/iterating_tables_in_batches/)
          # 2. Use materialized CTEs to apply unindexed filters (password_automatically_set, otp_required_for_login)
          #    on the bounded batch without pushing them into boundary queries
          # 3. Exclude webauthn registrations via subquery
          # 4. Count/Update only UserDetail records that need changes in a single SQL statement
          User.active.human
            .each_batch(of: @batch_size) do |batch|
            batch_num += 1
            updated = execute_batch_query(batch)
            total_updated += updated

            log("Batch #{batch_num}: #{updated} rows updated (cumulative: #{total_updated})")

            sleep(@batch_sleep) if @batch_sleep > 0
          end

          log("✓ Enrollment complete. Total users enrolled: #{total_updated}")
        end

        def enforce
          log("Enforcing Email OTP for all users")
          return if @dry_run

          update_mfa_requirement_setting(true)
          log("✓ Email OTP enforcement enabled. Users signing in with a password must now have some form of MFA.")
        end

        def unenforce
          log("Disabling mandatory enforcement of Email OTP for all users")
          return if @dry_run

          update_mfa_requirement_setting(false)
          log("✓ Email OTP enforcement disabled. Users can now choose to enroll or unenroll.")
        end

        private

        # Build and execute materialized CTE query; return count or affected rows
        def execute_batch_query(batch)
          batch_sql = batch.select(:id, :password_automatically_set, :otp_required_for_login).limit(@batch_size).to_sql

          sql = if @existing_enrol_at.nil?
                  build_new_enrollment_query(batch_sql)
                else
                  build_cohort_update_query(batch_sql)
                end

          query_result = ApplicationRecord.connection.execute(sql)
          @dry_run ? query_result.first['count'].to_i : query_result.cmd_tuples
        end

        # Use a CTE (Common Table Expression) for cohort updates.
        # Targets users with a password and no existing 2FA
        def build_new_enrollment_query(batch_sql)
          <<~SQL
            WITH batch AS MATERIALIZED (#{batch_sql}),
            filtered_batch AS MATERIALIZED (
              SELECT id FROM batch
              WHERE password_automatically_set IS NOT TRUE
                AND otp_required_for_login IS NOT TRUE
              LIMIT #{@batch_size}
            ),
            without_webauthn AS MATERIALIZED (
              SELECT filtered_batch.id FROM filtered_batch
              LEFT JOIN webauthn_registrations ON webauthn_registrations.user_id = filtered_batch.id
                AND webauthn_registrations.authentication_mode = 2
              WHERE webauthn_registrations.user_id IS NULL
              LIMIT #{@batch_size}
            )
            #{action_operation}
            WHERE user_id IN (SELECT id FROM without_webauthn) AND email_otp_required_after IS NULL
          SQL
        end

        # Use a CTE (Common Table Expression) for cohort updates
        # Cannot be memoized as it contains batch_sql which shifts its
        # window with each batch
        def build_cohort_update_query(batch_sql)
          safe_date = ApplicationRecord.connection.quote(@existing_enrol_at)
          <<~SQL
            WITH batch AS MATERIALIZED (#{batch_sql})
            #{action_operation}
            WHERE user_id IN (SELECT id FROM batch) AND email_otp_required_after = #{safe_date}
          SQL
        end

        # Memoize the action SQL (SELECT or COUNT) as it wont change
        # per batch
        def action_operation
          @action_operation ||= if @dry_run
                                  "SELECT COUNT(*) as count FROM user_details"
                                else
                                  safe_date = ApplicationRecord.connection.quote(@enrol_at)
                                  "UPDATE user_details SET email_otp_required_after = #{safe_date}"
                                end
        end

        def log(str)
          puts "[#{Time.current.iso8601}]#{'[DRY RUN]' if @dry_run} #{str}"
        end

        def confirm_settings
          puts "Dry Run: #{@dry_run ? 'Yes' : 'No'}"
          puts "Setting enrollment date: #{@enrol_at}"
          puts "Applying to existing enrollment date (target cohort): #{@existing_enrol_at}"
          puts "Batch Size: #{@batch_size}"
          puts "Sleep between batches: #{@batch_sleep}s"
          puts "Feature Flag (:email_based_mfa) enabled: #{::Feature.enabled?(:email_based_mfa) ? 'Yes' : 'No'}" # rubocop:disable Gitlab/FeatureFlagWithoutActor -- We explicitly want to validate it is enabled for all actors

          prompt = TTY::Prompt.new
          confirmed = prompt.yes?("Is this correct?", default: false)

          return if confirmed

          log('Aborting')
          abort
        end

        def update_mfa_requirement_setting(required)
          settings = ::ApplicationSetting.current_without_cache
          ::ApplicationSettings::UpdateService.new(settings, nil,
            { require_minimum_email_based_otp_for_users_with_passwords: required }).execute
        end
      end
    end
  end
end
