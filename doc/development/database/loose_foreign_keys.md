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
1. A job checks the `deleted_records` table every 5 minutes.
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

The YAML file is located at `lib/gitlab/database/gitlab_loose_foreign_keys.yml`. The file groups
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

To know about deletions in the `projects` table, configure a `DELETE` trigger using a database
migration (post-migration). The trigger needs to be configured only once. If the model already has
at least one `loose_foreign_key` definition, then this step can be skipped:

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

The migration should run after the `DELETE` trigger is installed. If the foreign key is deleted
earlier, there is a good chance of introducing data inconsistency which needs manual cleanup:

```ruby
class RemoveProjectsCiPipelineFk < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    remove_foreign_key_if_exists(:ci_pipelines, :projects, name: "fk_86635dbd80")
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
