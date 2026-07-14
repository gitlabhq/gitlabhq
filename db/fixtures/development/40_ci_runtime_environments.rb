# frozen_string_literal: true

# Usage:
#
# For every existing build that doesn't already have one, creates a
# Ci::BuildRuntimeEnvironment linked to a Ci::RuntimeEnvironment on the same
# project. Then tops up standalone (unlinked) Ci::RuntimeEnvironment rows, up
# to COUNT total, for query-plan volume testing. Safe to re-run: builds that
# already have a Ci::BuildRuntimeEnvironment are skipped, and RuntimeEnvironment
# top-up only creates the delta needed to reach COUNT.
#
# FILTER=40_ci_runtime_environments bundle exec rake db:seed_fu
#
# Increase the row count, useful when generating query plans for the
# Ci::RuntimeEnvironment.for_partition scope:
#
# FILTER=40_ci_runtime_environments COUNT=1000 bundle exec rake db:seed_fu

Gitlab::Seeder.quiet do
  count = [ENV.fetch('COUNT', 10).to_i, 1].max
  projects = Project.limit(10).to_a

  if projects.empty?
    puts "\nNo Project records found, run the 03_project seed first.\n"
  else
    # Ci::BuildRuntimeEnvironment is 1:1 per build (primary key is [build_id, partition_id]),
    # so only seed builds that don't already have one, to stay idempotent across reruns.
    # The linked Ci::RuntimeEnvironment must belong to the same project as the build,
    # matching the sharding_key: project_id invariant declared in db/docs for both tables.
    builds_without_runtime_environment =
      Ci::Build.left_joins(:build_runtime_environment)
        .where(ci_build_runtime_environments: { build_id: nil })
        .limit(count)

    builds_without_runtime_environment.each do |build|
      created_at = rand(Ci::RuntimeEnvironment::PARTITION_DURATION.to_i).seconds.ago

      runtime_environment = Ci::RuntimeEnvironment.create!(
        project_id: build.project_id,
        environment_key: "#{rand(1..1_000_000)}/s_#{SecureRandom.hex(4)}/executor-data",
        created_at: created_at,
        updated_at: created_at
      )

      Ci::BuildRuntimeEnvironment.create!(
        build: build,
        project_id: build.project_id,
        runtime_environment: runtime_environment
      )
    end

    # Top up standalone Ci::RuntimeEnvironment rows (not linked to any build) to
    # reach COUNT total, e.g. for query-plan volume testing.
    to_create = [count - Ci::RuntimeEnvironment.count, 0].max

    to_create.times do |i|
      project = projects.sample
      created_at = rand(Ci::RuntimeEnvironment::PARTITION_DURATION.to_i).seconds.ago

      print '.' if (i % 100).zero?

      Ci::RuntimeEnvironment.create!(
        project_id: project.id,
        environment_key: "#{rand(1..1_000_000)}/s_#{SecureRandom.hex(4)}/executor-data",
        created_at: created_at,
        updated_at: created_at
      )
    end
  end
end
