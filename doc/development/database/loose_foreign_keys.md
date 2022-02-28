---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Loose foreign keys

## Problem statement

In relational databases (including PostgreSQL), foreign keys provide a way to link
two database tables together, and ensure data-consistency between them. In GitLab,
[foreign keys](../foreign_keys.md) are vital part of the database design process.
Most of our database tables have foreign keys.

With the ongoing database [decomposition work](https://gitlab.com/groups/gitlab-org/-/epics/6168),
linked records might be present on two different database servers. Ensuring data consistency
between two databases is not possible with standard PostgreSQL foreign keys. PostgreSQL
does not support foreign keys operating within a single database server, defining
a link between two database tables in two different database servers over the network.

Example:

- Database "Main": `projects` table
- Database "CI": `ci_pipelines` table

A project can have many pipelines. When a project is deleted, the associated `ci_pipeline` (via the
`project_id` column) records must be also deleted.

With a multi-database setup, this cannot be achieved with foreign keys.

## Asynchronous approach

Our preferred approach to this problem is eventual consistency. With the loose foreign keys
feature, we can configure delayed association cleanup without negatively affecting the
application performance.

### How it works

In the previous example, a record in the `projects` table can have multiple `ci_pipeline`
records. To keep the cleanup process separate from the actual parent record deletion,
we can:

1. Create a `DELETE` trigger on the `projects` table.
   Record the deletions in a separate table (`deleted_records`).
1. A job checks the `deleted_records` table every minute or two.
1. For each record in the table, delete the associated `ci_pipelines` records
   using the `project_id` column.

NOTE:
For this procedure to work, we must register which tables to clean up asynchronously.

## Example migration and configuration

### Configure the loose foreign key

Loose foreign keys are defined in a YAML file. The configuration requires the
following information:

- Parent table name (`projects`)
- Child table name (`ci_pipelines`)
- The data cleanup method (`async_delete` or `async_nullify`)

The YAML file is located at `config/gitlab_loose_foreign_keys.yml`. The file groups
foreign key definitions by the name of the child table. The child table can have multiple loose
foreign key definitions, therefore we store them as an array.

Example definition:

```yaml
ci_pipelines:
  - table: projects
    column: project_id
    on_delete: async_delete
```

If the `ci_pipelines` key is already present in the YAML file, then a new entry can be added
to the array:

```yaml
ci_pipelines:
  - table: projects
    column: project_id
    on_delete: async_delete
  - table: another_table
    column: another_id
    on_delete: :async_nullify
```

### Track record changes

To know about deletions in the `projects` table, configure a `DELETE` trigger
using a [post-deployment migration](../post_deployment_migrations.md). The
trigger needs to be configured only once. If the model already has at least one
`loose_foreign_key` definition, then this step can be skipped:

```ruby
class TrackProjectRecordChanges < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    track_record_deletions(:projects)
  end

  def down
    untrack_record_deletions(:projects)
  end
end
```

### Remove the foreign key

If there is an existing foreign key, then it can be removed from the database. As of GitLab 14.5,
the following foreign key describes the link between the `projects` and `ci_pipelines` tables:

```sql
ALTER TABLE ONLY ci_pipelines
ADD CONSTRAINT fk_86635dbd80
FOREIGN KEY (project_id)
REFERENCES projects(id)
ON DELETE CASCADE;
```

The migration must run after the `DELETE` trigger is installed and the loose
foreign key definition is deployed. As such, it must be a [post-deployment
migration](../post_deployment_migrations.md) dated after the migration for the
trigger. If the foreign key is deleted earlier, there is a good chance of
introducing data inconsistency which needs manual cleanup:

```ruby
class RemoveProjectsCiPipelineFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_pipelines, :projects, name: "fk_86635dbd80")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_pipelines, :projects, name: "fk_86635dbd80", column: :project_id, target_column: :id, on_delete: "cascade")
  end
end
```

At this point, the setup phase is concluded. The deleted `projects` records should be automatically
picked up by the scheduled cleanup worker job.

## Testing

The "`it has loose foreign keys`" shared example can be used to test the presence of the `ON DELETE` trigger and the
loose foreign key definitions.

Simply add to the model test file:

```ruby
it_behaves_like 'it has loose foreign keys' do
  let(:factory_name) { :project }
end
```

**After** [removing a foreign key](#remove-the-foreign-key),
use the "`cleanup by a loose foreign key`" shared example to test a child record's deletion or nullification
via the added loose foreign key:

```ruby
it_behaves_like 'cleanup by a loose foreign key' do
  let!(:model) { create(:ci_pipeline, user: create(:user)) }
  let!(:parent) { model.user }
end
```

## Caveats of loose foreign keys

### Record creation

The feature provides an efficient way of cleaning up associated records after the parent record is
deleted. Without foreign keys, it's the application's responsibility to validate if the parent record
exists when a new associated record is created.

A bad example: record creation with the given ID (`project_id` comes from user input).
In this example, nothing prevents us from passing a random project ID:

```ruby
Ci::Pipeline.create!(project_id: params[:project_id])
```

A good example: record creation with extra check:

```ruby
project = Project.find(params[:project_id])
Ci::Pipeline.create!(project_id: project.id)
```

### Association lookup

Consider the following HTTP request:

```plaintext
GET /projects/5/pipelines/100
```

The controller action ignores the `project_id` parameter and finds the pipeline using the ID:

```ruby
  def show
  # bad, avoid it
  pipeline = Ci::Pipeline.find(params[:id]) # 100
end
```

This endpoint still works when the parent `Project` model is deleted. This can be considered a
a data leak which should not happen under normal circumstances:

```ruby
def show
  # good
  project = Project.find(params[:project_id])
  pipeline = project.pipelines.find(params[:pipeline_id]) # 100
end
```

NOTE:
This example is unlikely in GitLab, because we usually look up the parent models to perform
permission checks.

## A note on `dependent: :destroy` and `dependent: :nullify`

We considered using these Rails features as an alternative to foreign keys but there are several problems which include:

1. These run on a different connection in the context of a transaction [which we do not allow](multiple_databases.md#removing-cross-database-transactions).
1. These can lead to severe performance degradation as we load all records from PostgreSQL, loop over them in Ruby, and call individual `DELETE` queries.
1. These can miss data as they only cover the case when the `destroy` method is called directly on the model. There are other cases including `delete_all` and cascading deletes from another parent table that could mean these are missed.

For non-trivial objects that need to clean up data outside the
database (for example, object storage) where you might wish to use `dependent: :destroy`,
see alternatives in
[Avoid `dependent: :nullify` and `dependent: :destroy` across
databases](./multiple_databases.md#avoid-dependent-nullify-and-dependent-destroy-across-databases).

## Risks of loose foreign keys and possible mitigations

In general, the loose foreign keys architecture is eventually consistent and
the cleanup latency might lead to problems visible to GitLab users or
operators. We consider the tradeoff as acceptable, but there might be
cases where the problems are too frequent or too severe, and we must
implement a mitigation strategy. A general mitigation strategy might be to have
an "urgent" queue for cleanup of records that have higher impact with a delayed
cleanup.

Below are some more specific examples of problems that might occur and how we
might mitigate them. In all the listed cases we might still consider the problem
described to be low risk and low impact, and in that case we would choose to not
implement any mitigation.

### The record should be deleted but it shows up in a view

This hypothetical example might happen with a foreign key like:

```sql
ALTER TABLE ONLY vulnerability_occurrence_pipelines
    ADD CONSTRAINT fk_rails_6421e35d7d FOREIGN KEY (pipeline_id) REFERENCES ci_pipelines(id) ON DELETE CASCADE;
```

In this example we expect to delete all associated `vulnerability_occurrence_pipelines` records
whenever we delete the `ci_pipelines` record associated with them. In this case
you might end up with some vulnerability page in GitLab which shows an occurrence
of a vulnerability. However, when you try to click a link to the pipeline, you get
a 404, because the pipeline is deleted. Then, when you navigate back you might find the
occurrence has disappeared too.

**Mitigation**

When rendering the vulnerability occurrences on the vulnerability page we could
try to load the corresponding pipeline and choose to skip displaying that
occurrence if pipeline is not found.

### The deleted parent record is needed to render a view and causes a `500` error

This hypothetical example might happen with a foreign key like:

```sql
ALTER TABLE ONLY vulnerability_occurrence_pipelines
    ADD CONSTRAINT fk_rails_6421e35d7d FOREIGN KEY (pipeline_id) REFERENCES ci_pipelines(id) ON DELETE CASCADE;
```

In this example we expect to delete all associated `vulnerability_occurrence_pipelines` records
whenever we delete the `ci_pipelines` record associated with them. In this case
you might end up with a vulnerability page in GitLab which shows an "occurrence"
of a vulnerability. However, when rendering the occurrence we try to load, for example,
`occurrence.pipeline.created_at`, which causes a 500 for the user.

**Mitigation**

When rendering the vulnerability occurrences on the vulnerability page we could
try to load the corresponding pipeline and choose to skip displaying that
occurrence if pipeline is not found.

### The deleted parent record is accessed in a Sidekiq worker and causes a failed job

This hypothetical example might happen with a foreign key like:

```sql
ALTER TABLE ONLY vulnerability_occurrence_pipelines
    ADD CONSTRAINT fk_rails_6421e35d7d FOREIGN KEY (pipeline_id) REFERENCES ci_pipelines(id) ON DELETE CASCADE;
```

In this example we expect to delete all associated `vulnerability_occurrence_pipelines` records
whenever we delete the `ci_pipelines` record associated with them. In this case
you might end up with a Sidekiq worker that is responsible for processing a
vulnerability and looping over all occurrences causing a Sidekiq job to fail if
it executes `occurrence.pipeline.created_at`.

**Mitigation**

When looping through the vulnerability occurrences in the Sidekiq worker, we
could try to load the corresponding pipeline and choose to skip processing that
occurrence if pipeline is not found.
