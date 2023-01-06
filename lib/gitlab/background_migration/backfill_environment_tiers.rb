# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class backfills the `environments.tier` column by using `guess_tier` logic.
    # Environments created after 13.10 already have a value, however, environments created before 13.10 don't.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/300741 for more information.
    class BackfillEnvironmentTiers < BatchedMigrationJob
      operation_name :backfill_environment_tiers
      feature_category :database

      # Equivalent to `Environment#guess_tier` pattern matching.
      PRODUCTION_TIER = 0
      STAGING_TIER = 1
      TESTING_TIER = 2
      DEVELOPMENT_TIER = 3
      OTHER_TIER = 4

      TIER_REGEXP_PAIR = [
        { tier: DEVELOPMENT_TIER, regexp: '(dev|review|trunk)' },
        { tier: TESTING_TIER, regexp: '(test|tst|int|ac(ce|)pt|qa|qc|control|quality)' },
        { tier: STAGING_TIER, regexp: '(st(a|)g|mod(e|)l|pre|demo|non)' },
        { tier: PRODUCTION_TIER, regexp: '(pr(o|)d|live)' }
      ].freeze

      def perform
        TIER_REGEXP_PAIR.each do |pair|
          each_sub_batch(
            batching_scope: ->(relation) { relation.where(tier: nil).where("name ~* '#{pair[:regexp]}'") } # rubocop:disable GitlabSecurity/SqlInjection
          ) do |sub_batch|
            sub_batch.update_all(tier: pair[:tier])
          end
        end

        each_sub_batch(batching_scope: ->(relation) { relation.where(tier: nil) }) do |sub_batch|
          sub_batch.update_all(tier: OTHER_TIER)
        end
      end
    end
  end
end
