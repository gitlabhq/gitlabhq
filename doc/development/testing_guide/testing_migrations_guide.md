---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Testing Rails migrations at GitLab

In order to reliably check Rails migrations, we need to test them against
a database schema.

## When to write a migration test

- Post migrations (`/db/post_migrate`) and background migrations
  (`lib/gitlab/background_migration`) **must** have migration tests performed.
- If your migration is a data migration then it **must** have a migration test.
- Other migrations may have a migration test if necessary.

## How does it work?

Adding a `:migration` tag to a test signature enables some custom RSpec
`before` and `after` hooks in our
[`spec/support/migration.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/f81fa6ab1dd788b70ef44b85aaba1f31ffafae7d/spec/support/migration.rb)
to run.

A `before` hook will revert all migrations to the point that a migration
under test is not yet migrated.

In other words, our custom RSpec hooks will find a previous migration, and
migrate the database **down** to the previous migration version.

With this approach you can test a migration against a database schema.

An `after` hook will migrate the database **up** and reinstitute the latest
schema version, so that the process does not affect subsequent specs and
ensures proper isolation.

## Testing an `ActiveRecord::Migration` class

To test an `ActiveRecord::Migration` class (i.e., a
regular migration `db/migrate` or a post-migration `db/post_migrate`), you
will need to load the migration file by using the `require_migration!` helper
method because it is not autoloaded by Rails.

Example:

```ruby
require 'spec_helper'

require_migration!

RSpec.describe ...
```

### Test helpers

#### `require_migration!`

Since the migration files are not autoloaded by Rails, you will need to manually
load the migration file. To do so, you can use the `require_migration!` helper method
which can automatically load the correct migration file based on the spec file name.

For example, if your spec file is named as `populate_foo_column_spec.rb` then the
helper method will try to load `${schema_version}_populate_foo_column.rb` migration file.

In case there is no pattern between your spec file and the actual migration file,
you can provide the migration file name without the schema version, like so:

```ruby
require_migration!('populate_foo_column')
```

#### `table`

Use the `table` helper to create a temporary `ActiveRecord::Base`-derived model
for a table. [FactoryBot](best_practices.md#factories)
**should not** be used to create data for migration specs because it relies on
application code which can change after the migration has run, and cause the test
to fail. For example, to create a record in the `projects` table:

```ruby
project = table(:projects).create!(id: 1, name: 'gitlab1', path: 'gitlab1')
```

#### `migrate!`

Use the `migrate!` helper to run the migration that is under test. It will not only
run the migration, but will also bump the schema version in the `schema_migrations`
table. It is necessary because in the `after` hook we trigger the rest of
the migrations, and we need to know where to start. Example:

```ruby
it 'migrates successfully' do
  # ... pre-migration expectations

  migrate!

  # ... post-migration expectations
end
```

#### `reversible_migration`

Use the `reversible_migration` helper to test migrations with either a
`change` or both `up` and `down` hooks. This will test that the state of
the application and its data after the migration becomes reversed is the
same as it was before the migration ran in the first place. The helper:

1. Runs the `before` expectations before the **up** migration.
1. Migrates **up**.
1. Runs the `after` expectations.
1. Migrates **down**.
1. Runs the `before` expectations a second time.

Example:

```ruby
reversible_migration do |migration|
  migration.before -> {
    # ... pre-migration expectations
  }

  migration.after -> {
    # ... post-migration expectations
  }
end
```

### Example database migration test

This spec tests the
[`db/post_migrate/20170526185842_migrate_pipeline_stages.rb`](https://gitlab.com/gitlab-org/gitlab-foss/blob/v11.6.5/db/post_migrate/20170526185842_migrate_pipeline_stages.rb)
migration. You can find the complete spec in
[`spec/migrations/migrate_pipeline_stages_spec.rb`](https://gitlab.com/gitlab-org/gitlab-foss/blob/v11.6.5/spec/migrations/migrate_pipeline_stages_spec.rb).

```ruby
require 'spec_helper'

require_migration!

RSpec.describe MigratePipelineStages do
  # Create test data - pipeline and CI/CD jobs.
  let(:jobs) { table(:ci_builds) }
  let(:stages) { table(:ci_stages) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:projects) { table(:projects) }

  before do
    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    pipelines.create!(id: 1, project_id: 123, ref: 'master', sha: 'adf43c3a')
    jobs.create!(id: 1, commit_id: 1, project_id: 123, stage_idx: 2, stage: 'build')
    jobs.create!(id: 2, commit_id: 1, project_id: 123, stage_idx: 1, stage: 'test')
  end

  # Test just the up migration.
  it 'correctly migrates pipeline stages' do
    expect(stages.count).to be_zero

    migrate!

    expect(stages.count).to eq 2
    expect(stages.all.pluck(:name)).to match_array %w[test build]
  end

  # Test a reversible migration.
  it 'correctly migrates up and down pipeline stages' do
    reversible_migration do |migration|
      # Expectations will run before the up migration,
      # and then again after the down migration
      migration.before -> {
        expect(stages.count).to be_zero
      }

      # Expectations will run after the up migration.
      migration.after -> {
        expect(stages.count).to eq 2
        expect(stages.all.pluck(:name)).to match_array %w[test build]
      }
    end
end
```

## Testing a non-`ActiveRecord::Migration` class

To test a non-`ActiveRecord::Migration` test (a background migration),
you will need to manually provide a required schema version. Please add a
`schema` tag to a context that you want to switch the database schema within.

If not set, `schema` defaults to `:latest`.

Example:

```ruby
describe SomeClass, schema: 20170608152748 do
  # ...
end
```

### Example background migration test

This spec tests the
[`lib/gitlab/background_migration/archive_legacy_traces.rb`](https://gitlab.com/gitlab-org/gitlab-foss/blob/v11.6.5/lib/gitlab/background_migration/archive_legacy_traces.rb)
background migration. You can find the complete spec on
[`spec/lib/gitlab/background_migration/archive_legacy_traces_spec.rb`](https://gitlab.com/gitlab-org/gitlab-foss/blob/v11.6.5/spec/lib/gitlab/background_migration/archive_legacy_traces_spec.rb)

```ruby
require 'spec_helper'

describe Gitlab::BackgroundMigration::ArchiveLegacyTraces, schema: 20180529152628 do
  include TraceHelpers

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:builds) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  before do
    namespaces.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
    @build = builds.create!(id: 1, project_id: 123, status: 'success', type: 'Ci::Build')
  end

  context 'when trace file exists at the right place' do
    before do
      create_legacy_trace(@build, 'trace in file')
    end

    it 'correctly archive legacy traces' do
      expect(job_artifacts.count).to eq(0)
      expect(File.exist?(legacy_trace_path(@build))).to be_truthy

      described_class.new.perform(1, 1)

      expect(job_artifacts.count).to eq(1)
      expect(File.exist?(legacy_trace_path(@build))).to be_falsy
      expect(File.read(archived_trace_path(job_artifacts.first))).to eq('trace in file')
    end
  end
end
```

These tests do not run within a database transaction, as we use a deletion database
cleanup strategy. Do not depend on a transaction being present.
