---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Testing Rails migrations at GitLab
---

In order to reliably check Rails migrations, we need to test them against
a database schema.

## When to write a migration test

- Post migrations (`/db/post_migrate`) and background migrations
  (`lib/gitlab/background_migration`) **must** have migration tests performed.
- If your migration is a data migration then it **must** have a migration test.
- Other migrations may have a migration test if necessary.

We don't enforce tests on post migrations that only perform schema changes.

## How does it work?

All specs in `(ee/)spec/migrations/` and `spec/lib/(ee/)background_migrations` are automatically
tagged with the `:migration` RSpec tag. This tag enables some custom RSpec
`before` and `after` hooks in our
[`spec/support/migration.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/f81fa6ab1dd788b70ef44b85aaba1f31ffafae7d/spec/support/migration.rb)
to run. If performing a migration against a database schema other than
`:gitlab_main` (for example `:gitlab_ci`), then you must explicitly specify it
with an RSpec tag like: `migration: :gitlab_ci`. See
[spec/migrations/change_public_projects_cost_factor_spec.rb](https://gitlab.com/gitlab-org/gitlab/blob/master/spec/migrations/change_public_projects_cost_factor_spec.rb#L6-6)
for an example.

A `before` hook reverts all migrations to the point that a migration
under test is not yet migrated.

In other words, our custom RSpec hooks finds a previous migration, and
migrate the database **down** to the previous migration version.

With this approach you can test a migration against a database schema.

An `after` hook migrates the database **up** and restores the latest
schema version, so that the process does not affect subsequent specs and
ensures proper isolation.

## Testing an `ActiveRecord::Migration` class

To test an `ActiveRecord::Migration` class (for example, a
regular migration `db/migrate` or a post-migration `db/post_migrate`), you
must load the migration file by using the `require_migration!` helper
method because it is not autoloaded by Rails.

Example:

```ruby
require 'spec_helper'

require_migration!

RSpec.describe ...
```

### Test helpers

#### `require_migration!`

Since the migration files are not autoloaded by Rails, you must manually
load the migration file. To do so, you can use the `require_migration!` helper method
which can automatically load the correct migration file based on the spec filename.

You can use `require_migration!` to load migration files from spec files
that contain the schema version in the filename (for example,
`2021101412150000_populate_foo_column_spec.rb`).

```ruby
# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe PopulateFooColumn do
  ...
end
```

In some cases, you must require multiple migration files to use them in your specs. Here, there's no
pattern between your spec file and the other migration file. You can provide the migration filename like so:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require_migration!
require_migration!('populate_bar_column')

RSpec.describe PopulateFooColumn do
  ...
end
```

#### `table`

Use the `table` helper to create a temporary `ActiveRecord::Base`-derived model
for a table. [FactoryBot](best_practices.md#factories)
**should not** be used to create data for migration specs because it relies on
application code which can change after the migration has run, and cause the test
to fail. For example, to create a record in the `projects` table:

```ruby
project = table(:projects).create!(name: 'gitlab1', path: 'gitlab1')
```

#### `migrate!`

Use the `migrate!` helper to run the migration that is under test. It
runs the migration and bumps the schema version in the `schema_migrations`
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
`change` or both `up` and `down` hooks. This tests that the state of
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

### Custom matchers for post-deployment migrations

We have some custom matchers in
[`spec/support/matchers/background_migrations_matchers.rb`](https://gitlab.com/gitlab-org/gitlab/blob/v14.1.0-ee/spec/support/matchers/background_migrations_matchers.rb)
to verify background migrations were correctly scheduled from a post-deployment migration, and
receive the correct number of arguments.

All of them use the internal matcher `be_background_migration_with_arguments`, which verifies that
the `#perform` method on your migration class doesn't crash when receiving the provided arguments.

#### `be_scheduled_migration`

Verifies that a Sidekiq job was queued with the expected class and arguments.

This matcher usually makes sense if you're queueing jobs manually, rather than going through our helpers.

```ruby
# Migration
BackgroundMigrationWorker.perform_async('MigrationClass', args)

# Spec
expect('MigrationClass').to be_scheduled_migration(*args)
```

#### `be_scheduled_migration_with_multiple_args`

Verifies that a Sidekiq job was queued with the expected class and arguments.

This works the same as `be_scheduled_migration`, except that the order is ignored when comparing
array arguments.

```ruby
# Migration
BackgroundMigrationWorker.perform_async('MigrationClass', ['foo', [3, 2, 1]])

# Spec
expect('MigrationClass').to be_scheduled_migration_with_multiple_args('foo', [1, 2, 3])
```

#### `be_scheduled_delayed_migration`

Verifies that a Sidekiq job was queued with the expected delay, class, and arguments.

This can also be used with `queue_background_migration_jobs_by_range_at_intervals` and related helpers.

```ruby
# Migration
BackgroundMigrationWorker.perform_in(delay, 'MigrationClass', args)

# Spec
expect('MigrationClass').to be_scheduled_delayed_migration(delay, *args)
```

#### `have_scheduled_batched_migration`

Verifies that a `BatchedMigration` record was created with the expected class and arguments.

The `*args` are additional arguments passed to the `MigrationClass`, while `**kwargs` are any other
attributes to be verified on the `BatchedMigration` record (Example: `interval: 2.minutes`).

```ruby
# Migration
queue_batched_background_migration(
  'MigrationClass',
  table_name,
  column_name,
  *args,
  **kwargs
)

# Spec
expect('MigrationClass').to have_scheduled_batched_migration(
  table_name: table_name,
  column_name: column_name,
  job_arguments: args,
  **kwargs
)
```

#### `be_finalize_background_migration_of`

Verifies that a migration calls `finalize_background_migration` with the expected background migration class.

```ruby
# Migration
finalize_background_migration('MigrationClass')

# Spec
expect(described_class).to be_finalize_background_migration_of('MigrationClass')
```

### Examples of migration tests

Migration tests depend on what the migration does exactly, the most common types are data migrations and scheduling background migrations.

#### Example of a data migration test

This spec tests the
[`db/post_migrate/20200723040950_migrate_incident_issues_to_incident_type.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/post_migrate/20200723040950_migrate_incident_issues_to_incident_type.rb)
migration. You can find the complete spec in
[`spec/migrations/migrate_incident_issues_to_incident_type_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/migrations/migrate_incident_issues_to_incident_type_spec.rb).

```ruby
# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateIncidentIssuesToIncidentType do
  let(:migration) { described_class.new }

  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:labels) { table(:labels) }
  let(:issues) { table(:issues) }
  let(:label_links) { table(:label_links) }
  let(:label_props) { IncidentManagement::CreateIncidentLabelService::LABEL_PROPERTIES }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let(:label) { labels.create!(project_id: project.id, **label_props) }
  let!(:incident_issue) { issues.create!(project_id: project.id) }
  let!(:other_issue) { issues.create!(project_id: project.id) }

  # Issue issue_type enum
  let(:issue_type) { 0 }
  let(:incident_type) { 1 }

  before do
    label_links.create!(target_id: incident_issue.id, label_id: label.id, target_type: 'Issue')
  end

  describe '#up' do
    it 'updates the incident issue type' do
      expect { migrate! }
        .to change { incident_issue.reload.issue_type }
        .from(issue_type)
        .to(incident_type)

      expect(other_issue.reload.issue_type).to eq(issue_type)
    end
  end

  describe '#down' do
    let!(:incident_issue) { issues.create!(project_id: project.id, issue_type: issue_type) }

    it 'updates the incident issue type' do
      migration.up

      expect { migration.down }
        .to change { incident_issue.reload.issue_type }
        .from(incident_type)
        .to(issue_type)

      expect(other_issue.reload.issue_type).to eql(issue_type)
    end
  end
end
```

#### Example of a background migration scheduling test

To test these you usually have to:

- Create some records.
- Run the migration.
- Verify that the expected jobs were scheduled, with the correct set
  of records, the correct batch size, interval, etc.

The behavior of the background migration itself needs to be verified in a
[separate test for the background migration class](#example-background-migration-test).

This spec tests the
[`db/post_migrate/20210701111909_backfill_issues_upvotes_count.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/v14.1.0-ee/db/post_migrate/20210701111909_backfill_issues_upvotes_count.rb)
post-deployment migration. You can find the complete spec in
[`spec/migrations/backfill_issues_upvotes_count_spec.rb`](https://gitlab.com/gitlab-org/gitlab/blob/v14.1.0-ee/spec/spec/migrations/backfill_issues_upvotes_count_spec.rb).

```ruby
require 'spec_helper'
require_migration!

RSpec.describe BackfillIssuesUpvotesCount do
  let(:migration) { described_class.new }
  let(:issues) { table(:issues) }
  let(:award_emoji) { table(:award_emoji) }

  let!(:issue1) { issues.create! }
  let!(:issue2) { issues.create! }
  let!(:issue3) { issues.create! }
  let!(:issue4) { issues.create! }
  let!(:issue4_without_thumbsup) { issues.create! }

  let!(:award_emoji1) { award_emoji.create!( name: 'thumbsup', awardable_type: 'Issue', awardable_id: issue1.id) }
  let!(:award_emoji2) { award_emoji.create!( name: 'thumbsup', awardable_type: 'Issue', awardable_id: issue2.id) }
  let!(:award_emoji3) { award_emoji.create!( name: 'thumbsup', awardable_type: 'Issue', awardable_id: issue3.id) }
  let!(:award_emoji4) { award_emoji.create!( name: 'thumbsup', awardable_type: 'Issue', awardable_id: issue4.id) }

  it 'correctly schedules background migrations', :aggregate_failures do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_migration(issue1.id, issue2.id)
        expect(described_class::MIGRATION).to be_scheduled_migration(issue3.id, issue4.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
```

## Testing a non-`ActiveRecord::Migration` class

To test a non-`ActiveRecord::Migration` test (a background migration),
you must manually provide a required schema version. Add a
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
[`lib/gitlab/background_migration/backfill_draft_status_on_merge_requests.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/background_migration/backfill_draft_status_on_merge_requests.rb)
background migration. You can find the complete spec on
[`spec/lib/gitlab/background_migration/backfill_draft_status_on_merge_requests_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/lib/gitlab/background_migration/backfill_draft_status_on_merge_requests_spec.rb)

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDraftStatusOnMergeRequests do
  let(:namespaces)     { table(:namespaces) }
  let(:projects)       { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }

  let(:group)   { namespaces.create!(name: 'gitlab', path: 'gitlab') }
  let(:project) { projects.create!(namespace_id: group.id) }

  let(:draft_prefixes) { ["[Draft]", "(Draft)", "Draft:", "Draft", "[WIP]", "WIP:", "WIP"] }

  def create_merge_request(params)
    common_params = {
      target_project_id: project.id,
      target_branch: 'feature1',
      source_branch: 'master'
    }

    merge_requests.create!(common_params.merge(params))
  end

  context "for MRs with #draft? == true titles but draft attribute false" do
    let(:mr_ids) { merge_requests.all.collect(&:id) }

    before do
      draft_prefixes.each do |prefix|
        (1..4).each do |n|
          create_merge_request(
            title: "#{prefix} This is a title",
            draft: false,
            state_id: n
          )
        end
      end
    end

    it "updates all open draft merge request's draft field to true" do
      mr_count = merge_requests.all.count

      expect { subject.perform(mr_ids.first, mr_ids.last) }
        .to change { MergeRequest.where(draft: false).count }
              .from(mr_count).to(mr_count - draft_prefixes.length)
    end

    it "marks successful slices as completed" do
      expect(subject).to receive(:mark_job_as_succeeded).with(mr_ids.first, mr_ids.last)

      subject.perform(mr_ids.first, mr_ids.last)
    end
  end
end
```

These tests do not run within a database transaction, as we use a deletion database
cleanup strategy. Do not depend on a transaction being present.

When testing migrations that alter seeded data in `deletion_except_tables`, you may add the
`:migration_with_transaction` metadata so the test runs within a transaction and the data
is rolled back to their original values.
