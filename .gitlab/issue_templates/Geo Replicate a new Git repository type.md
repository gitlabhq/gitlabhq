

## Replicate Cool Widgets - Repository

This issue is for implementing Geo replication and verification of Cool Widgets.

For more background, see [Geo self-service framework](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/geo/framework.md).

In order to implement and test this feature, you need to first [set up Geo locally](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/geo.md).

There are two main sections below. It is a good idea to structure your merge requests this way as well:

1. Generate Geo SSF boilerplate and apply manual adjustments
1. Release Geo support of Cool Widgets

You can look into the following example for implementing replication/verification for a new Git repository type:
- [Add snippet repository verification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56596)

### Generate Geo SSF boilerplate

The `geo:repository_replicator` Rails generator automates the creation of all boilerplate files and patches required by the Geo Self-Service Framework for a new Git repository replicator. Run `rails generate geo:repository_replicator --help` for the full option list.

#### Step 1. Run the generator

- [ ] Run the generator with the appropriate options:

  ```bash
  rails generate geo:repository_replicator cool_widget \
    --model-class=CoolWidget \
    --table-name=cool_widgets \
    --sharding-key=project_id \
    --milestone=XX.Y

  # Dry run (preview without writing)
  rails generate geo:repository_replicator cool_widget \
    --model-class=CoolWidget \
    --table-name=cool_widgets \
    --sharding-key=project_id \
    --milestone=XX.Y \
    --pretend
  ```

  **Options:**
  | Option | Description |
  |---|---|
  | `NAME` | Snake_case replicable name, passed as the positional argument (e.g. `cool_widget`) |
  | `--model-class` | Ruby model class name (e.g. `CoolWidget`) |
  | `--table-name` | Database table name (e.g. `cool_widgets`) |
  | `--sharding-key` | Sharding key column(s): `project_id`, `namespace_id`, `organization_id`, or `uploaded_by_user_id`. Space- or comma-separated for multiple keys. |
  | `--milestone` | Milestone version (e.g. `18.10`) |
  | `--pretend` | Preview without writing |
  | `--skip-post-generate` | Skip the post-generation rake tasks and RuboCop autocorrect |
  | `--only-post-generate` | Post-rebase: skip new-file creation, but re-apply the (idempotent) framework patches and re-run the derived-doc regeneration rake tasks (and RuboCop autocorrect) |

  The generator creates the replicator (using `RepositoryReplicatorStrategy`), the registry and
  state models, the Geo tracking-DB registry migration and main-DB states migration, the registry
  finder, the GraphQL resolver/type, the ops feature flags, the DB dictionaries, factories and
  specs. It wires the existing model in place (adds `::Geo::ReplicableModel`/`VerifiableModel`,
  `with_replicator`, the state association, `pool_repository`, and a generated `selective_sync_scope`
  stub) and patches the framework lists (`REPLICATOR_CLASSES`, `REGISTRY_CLASSES`, `geo_node_type`,
  `registrable_type`, inflections, the registry-class enum, the shared contexts/specs, the status
  fixtures, and the API/Prometheus docs). It then regenerates the derived docs/metrics and runs
  `rubocop --autocorrect` over the generated and patched Ruby.

#### Step 2. Run migrations and commit generated schema files

- [ ] Run Geo tracking database migration:

  ```shell
  bin/rake db:migrate:geo
  ```

- [ ] Run main database migration:

  ```shell
  bin/rake db:migrate
  ```

- [ ] Commit the generated `db/structure.sql`, `ee/db/geo/structure.sql`, and `schema_migrations` changes.

#### Step 3. Apply manual adjustments

The generator handles most of the boilerplate, but repository types need model-specific work it
cannot infer:

- [ ] **Review the generated model wiring** in `ee/app/models/ee/cool_widget.rb` (or the CoolWidget
  model). The generator adds the Geo concerns, the state association, `verification_state_object`,
  `pool_repository` (returns `nil`), and a `cool_widget_state` builder. Ensure `CoolWidget` has
  `prepend_mod_with('CoolWidget')` so the EE concern loads.
- [ ] **Implement `CoolWidget.selective_sync_scope`** — the generated body is a sharding-key default
  and is almost certainly not correct for a repository type. See
  `ee/app/models/ee/projects/wiki_repository.rb` and `ee/app/models/group_wiki_repository.rb` for
  examples (namespace/shard/organization filtering). Ensure it is well-tested.
- [ ] **Implement `#repository`** in `ee/app/replicators/geo/cool_widget_replicator.rb` to return the
  `<Repository>` instance for the model record, and decide `housekeeping_enabled?` (the generated
  stub returns `false`; return `true` only if the type supports git housekeeping and implements
  `#git_garbage_collect_worker_klass`).
- [ ] Add verification traits to the `cool_widget` factory and the Geo replication shared examples to
  its model spec (`ee/spec/models/ee/cool_widget_spec.rb`):

  ```ruby
  describe 'Geo replication', feature_category: :geo_replication do
    include_examples 'a verifiable model for verification state' do
      let(:verifiable_model_record) { build(:cool_widget) }
      let(:unverifiable_model_record) { build(:cool_widget) }
    end

    describe 'replication/verification' do
      # set up records in/out of selective sync, then:
      include_examples 'Geo Framework selective sync behavior'
    end
  end
  ```

- [ ] **Register the repository update event** by adding a `when <Container>` branch for the new type
  to `Repository#log_geo_updated_event` in `ee/app/models/ee/repository.rb`:

  ```ruby
  when CoolWidget # Add the new repository type here
    container.geo_handle_after_update
  ```

  See `app/workers/post_receive.rb` for more examples.

- [ ] **Handle repository removal** — add something like the following in the destroy service of the
  repository:

  ```ruby
  cool_widget.replicator.geo_handle_after_destroy if cool_widget.repository
  ```

- [ ] **Allow Geo to request and download the repository** — you may need to update
  `Gitlab::GitAccessCoolWidget`. For example, see
  [this change for Group-level Wikis](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54914/diffs?commit_id=0f2b36f66697b4addbc69bd377ee2818f648dd33).

- [ ] If the model's "last updated" timestamp is not `updated_at`, set `self.model_updated_last` (and
  `self.model_updated_scope` if needed) in `ee/app/models/geo/cool_widget_registry.rb`.

- [ ] Fill `introduced_by_url`/`rollout_issue_url` in the generated feature flag YAML files.

#### Step 4. Run post-generation tasks

The generator runs these automatically. Run them manually only if you passed `--skip-post-generate`:

- [ ] Run: `tooling/bin/gettext_extractor locale/gitlab.pot`
- [ ] Run: `bundle exec rake gitlab:geo:dev:ssf_metrics`
- [ ] Run: `bundle exec rake gitlab:graphql:compile_docs`
- [ ] Run: `bundle exec rake gitlab:graphql:generate_all_introspection_schemas`
- [ ] Run: `bundle exec rake gitlab:openapi:v3:generate`

#### Step 5. Handle batch destroy

If batch destroy logic is implemented for a replicable, then that logic must be "replicated" by Geo secondaries. The easiest way to do this is to use `Geo::BatchEventCreateWorker` to bulk insert a delete event for each replicable.

Batch destroy logic cannot be handled automatically by Geo secondaries. It is up to you to produce `Geo::BatchEventCreateWorker` attributes before the records are deleted, and then enqueue `Geo::BatchEventCreateWorker` after the records are deleted.

- [ ] Ensure that any batch destroy of this replicable is replicated to secondary sites.
- [ ] Verify in specs that when the parent object is removed, the new `Geo::Event` records are created.

### Code Review

When requesting review from database reviewers:

- [ ] Include a comment mentioning that the change is based on a documented template and the generator.
- [ ] `selective_sync_scope` and `available_replicables` may differ per Model. If their queries are new, then add [query plans](https://docs.gitlab.com/development/database_review/#query-plans) to the MR description. An easy place to gather SQL queries is your GDK's `log/test.log` when running tests of these methods.

### Release Geo support of Cool Widgets

- [ ] In the rollout issue you created when creating the feature flag, modify the Roll Out Steps:
  - [ ] Cross out any steps related to testing on production GitLab.com, because Geo is not running on production GitLab.com at the moment.
  - [ ] Add a step to `Test replication and verification of Cool Widgets on a non-GDK-deployment. For example, using GitLab Environment Toolkit`.
  - [ ] Add a step to `Ping the Geo PM and EM to coordinate testing`.
- [ ] In the generated feature flag YAML file, set `default_enabled: true`.
- [ ] In `ee/app/graphql/types/geo/geo_node_type.rb`, remove the `experiment` option for the released type.
- [ ] Run `bundle exec rake gitlab:graphql:compile_docs` after the step above to regenerate the GraphQL docs.
- [ ] Add a row for Cool Widgets to the `Data types` table in [Geo data types support](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/geo/replication/datatypes.md#data-types).
- [ ] Add a row for Cool Widgets to the `Limitations on replication/verification` table in [Geo data types support](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/geo/replication/datatypes.md#limitations-on-replicationverification). If the row already exists, then update it to show that Replication and Verification is released in the current version.
- [ ] Add the `cool_widget` model name to the list of allowed models in the [Data Management API documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/api/admin/data_management.md#retrieve-model-information).
