

## Replicate Cool Widgets - Blob

This issue is for implementing Geo replication and verification of Cool Widgets.

For more background, see [Geo self-service framework](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/geo/framework.md).

In order to implement and test this feature, you need to first [set up Geo locally](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/geo.md).

There are three main sections below. It is a good idea to structure your merge requests this way as well:

1. Generate Geo SSF boilerplate and apply manual adjustments
1. Release Geo support of Cool Widgets

You can look into the following examples of MRs for implementing replication/verification for a new blob type:
- [Add db changes](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60935) and [add verification for MR diffs using SSF](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63309)
- [Verify Terraform state versions](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58800)
- [Verify LFS objects](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63981)

### Generate Geo SSF boilerplate

The [`scripts/geo/generate-blob-replicator`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/geo/generate-blob-replicator) script automates the creation of all boilerplate files and patches required by the Geo Self-Service Framework for a new blob replicator.

#### Step 1. Run the generator

- [ ] Run the generator script with the appropriate options:

  ```bash
  # Standard blob replicator
  scripts/geo/generate-blob-replicator \
    --replicable-name=cool_widget \
    --model-class=CoolWidget \
    --table-name=cool_widgets \
    --sharding-key=project_id \
    --milestone=XX.Y

  # Upload partition replicator (for upload partition tables)
  scripts/geo/generate-blob-replicator \
    --replicable-name=cool_widget_upload \
    --model-class=CoolWidget \
    --table-name=cool_widget_uploads \
    --sharding-key=organization_id \
    --milestone=XX.Y \
    --upload-partition

  # Dry run (preview without writing)
  scripts/geo/generate-blob-replicator \
    --replicable-name=cool_widget \
    --model-class=CoolWidget \
    --table-name=cool_widgets \
    --sharding-key=project_id \
    --milestone=XX.Y \
    --dry-run
  ```

  **Options:**
  | Option | Description |
  |---|---|
  | `--replicable-name` | Snake_case replicable name (e.g. `cool_widget`) |
  | `--model-class` | Ruby model class name (e.g. `CoolWidget`) |
  | `--table-name` | Database table name (e.g. `cool_widgets`) |
  | `--sharding-key` | Sharding key column(s): `project_id`, `namespace_id`, or `organization_id`. Can be comma-separated for multiple keys. |
  | `--milestone` | Milestone version (e.g. `18.10`) |
  | `--upload-partition` | Generate a dedicated read-only model for an upload partition table |
  | `--dry-run` | Print file paths without writing |

  The script generates 17+ new files and patches 14+ existing files. See the script's output for the full list.

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

The generator handles most of the boilerplate, but some steps still require manual work:

- [ ] **For standard mode (without `--upload-partition`):** Add model concerns to the `CoolWidget` model:
  - Include `::Geo::ReplicableModel` in the `CoolWidget` class, and specify the Replicator class `with_replicator Geo::CoolWidgetReplicator`.
  - Include the `::Geo::VerifiableModel` concern.
  - Delegate verification related methods to the `cool_widget_state` model.
  - For verification, override some scopes to use the `cool_widget_states` table instead of the model table.
  - Implement the `verification_state_object` method to return the object that holds the verification details.
  - Implement `selective_sync_scope` (see below).
  - Override some methods to use the `cool_widget_states` table in verification-related queries.

  At this point the `CoolWidget` class should look like this:

  ```ruby
  # frozen_string_literal: true

  class CoolWidget < ApplicationRecord
    ...
    include ::Geo::ReplicableModel
    include ::Geo::VerifiableModel

    delegate(*::Geo::VerificationState::VERIFICATION_METHODS, to: :cool_widget_state)

    with_replicator Geo::CoolWidgetReplicator

    mount_uploader :file, CoolWidgetUploader

    has_one :cool_widget_state, autosave: false, inverse_of: :cool_widget, class_name: 'Geo::CoolWidgetState'

    scope :with_verification_state, ->(state) {
      joins(:cool_widget_state)
        .where(cool_widget_states: { verification_state: verification_state_value(state) })
    }

    # Add this scope if your replicable belongs to a project
    scope :project_id_in, ->(ids) { where(project_id: ids) }

    # OR add this scope if your replicable belongs to a group
    # scope :group_id_in, ->(ids) { joins(:group).merge(::Namespace.id_in(ids)) }

    # OR add this scope if your replicable belongs to an organization
    # scope :organization_id_in, ->(ids) { where(organization_id: ids) }

    def verification_state_object
      cool_widget_state
    end
    ...

    class_methods do
      extend ::Gitlab::Utils::Override
      ...

      override :selective_sync_scope
      def selective_sync_scope(node, **params)
        # See the generated upload partition model for an example implementation,
        # or search the codebase for other examples.
        # Consult a Geo expert if needed.
      end

      override :verification_state_model_key
      def verification_state_model_key
        :cool_widget_id
      end

      override :verification_state_table_class
      def verification_state_table_class
        CoolWidgetState
      end
    end

    def cool_widget_state
      super || build_cool_widget_state
    end

    ...
  end
  ```

- [ ] **For `--upload-partition` mode:** Review the auto-generated model in `ee/app/models/geo/` and adjust if needed.

- [ ] Implement `CoolWidget.selective_sync_scope` (for standard mode) or review the generated one (for upload partition mode).
- [ ] Ensure `CoolWidget.selective_sync_scope` is well-tested.

- [ ] Add the following to `ee/spec/factories/cool_widgets.rb` (for standard mode only; upload partition mode generates this automatically):

  ```ruby
  # frozen_string_literal: true

  FactoryBot.modify do
    factory :cool_widget do
      trait :verification_succeeded do
        with_file
        verification_checksum { 'abc' }
        verification_state { CoolWidget.verification_state_value(:verification_succeeded) }
      end

      trait :verification_failed do
        with_file
        verification_failure { 'Could not calculate the checksum' }
        verification_state { CoolWidget.verification_state_value(:verification_failed) }

        after(:create) do |instance, _|
          instance.verification_failed!
        end
      end
    end
  end
  ```

  If there is not an existing factory for the object in `spec/factories/cool_widgets.rb`, wrap the traits in `FactoryBot.create` instead of `FactoryBot.modify`.

- [ ] Make sure the factory supports the `:remote_store` trait. If not, add something like:

  ```ruby
  trait :remote_store do
    file_store { CoolWidget::FileUploader::Store::REMOTE }
  end
  ```

- [ ] Make sure the factory also allows setting a `project` attribute. If the model does not have a direct relation to a project, you can use a `transient` attribute. Check out `spec/factories/merge_request_diffs.rb` for an example.

- [ ] Add a custom factory name if needed in `def model_class_factory_name` in `ee/spec/support/helpers/ee/geo_helpers.rb`.
- [ ] Add `[:cool_widget, :remote_store]` to `skipped` in `spec/support/shared_examples/lint_factories_shared_examples.rb`.

#### Step 4. Run post-generation tasks

- [ ] Run: `tooling/bin/gettext_extractor locale/gitlab.pot`
- [ ] Run: `bundle exec rake gitlab:geo:dev:ssf_metrics`
- [ ] Run: `bundle exec rake gitlab:graphql:compile_docs`
- [ ] Run: `bundle exec rake gitlab:graphql:generate_all_introspection_schemas`
- [ ] Run: `bundle exec rake gitlab:openapi:v2:generate`
- [ ] Run: `bundle exec rake gitlab:openapi:v3:generate`

#### Step 5. Handle batch destroy

If batch destroy logic is implemented for a replicable, then that logic must be "replicated" by Geo secondaries. The easiest way to do this is use `Geo::BatchEventCreateWorker` to bulk insert a delete event for each replicable.

For example, if `FastDestroyAll` is used, then you may be able to [use `begin_fast_destroy` and `finalize_fast_destroy` hooks, like we did for uploads](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/69763).

Or if a special service is used to batch delete records and their associated data, then you probably need to [hook into that service, like we did for job artifacts](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79530).

As illustrated by the above two examples, batch destroy logic cannot be handled automatically by Geo secondaries without restricting the way other teams perform batch destroys. It is up to you to produce `Geo::BatchEventCreateWorker` attributes before the records are deleted, and then enqueue `Geo::BatchEventCreateWorker` after the records are deleted.

- [ ] Ensure that any batch destroy of this replicable is replicated to secondary sites
- [ ] Regardless of implementation details, please verify in specs that when the parent object is removed, the new `Geo::Event` records are created:

```ruby
  describe '#destroy' do
    subject { create(:cool_widget) }

    context 'when running in a Geo primary node' do
      let_it_be(:primary) { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }

      it 'logs an event to the Geo event log when bulk removal is used', :sidekiq_inline do
        stub_current_geo_node(primary)

        expect { subject.project.destroy! }.to change(Geo::Event.where(replicable_name: :cool_widget, event_name: :deleted), :count).by(1)

        payload = Geo::Event.where(replicable_name: :cool_widget, event_name: :deleted).last.payload

        expect(payload['model_record_id']).to eq(subject.id)
        expect(payload['blob_path']).to eq(subject.relative_path)
        expect(payload['uploader_class']).to eq('CoolWidgetUploader')
      end
    end
  end
```

### Code Review

When requesting review from database reviewers:

- [ ] Include a comment mentioning that the change is based on a documented template and the generator script.
- [ ] `selective_sync_scope` and `available_replicables` may differ per Model. If their queries are new, then add [query plans](https://docs.gitlab.com/development/database_review/#query-plans) to the MR description. An easy place to gather SQL queries is your GDK's `log/test.log` when running tests of these methods.

### Release Geo support of Cool Widgets

- [ ] In the rollout issue you created when creating the feature flag, modify the Roll Out Steps:
  - [ ] Cross out any steps related to testing on production GitLab.com, because Geo is not running on production GitLab.com at the moment.
  - [ ] Add a step to `Test replication and verification of Cool Widgets on a non-GDK-deployment. For example, using GitLab Environment Toolkit`.
  - [ ] Add a step to `Ping the Geo PM and EM to coordinate testing`. For example, you might add steps to generate Cool Widgets, and then a Geo engineer may take it from there.
- [ ] In the generated feature flag YAML file, set `default_enabled: true`
- [ ] In `ee/app/graphql/types/geo/geo_node_type.rb`, remove the `experiment` option for the released type.
- [ ] Run `bundle exec rake gitlab:graphql:compile_docs` after the step above to regenerate the GraphQL docs.
- [ ] Add a row for Cool Widgets to the `Data types` table in [Geo data types support](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/geo/replication/datatypes.md#data-types)
- [ ] Add a row for Cool Widgets to the `Limitations on replication/verification` table in [Geo data types support](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/geo/replication/datatypes.md#limitations-on-replicationverification). If the row already exists, then update it to show that Replication and Verification is released in the current version.
- [ ] Add the `cool_widget` model name to the list of allowed models in the [Data Management API documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/api/admin/data_management.md#retrieve-model-information)
