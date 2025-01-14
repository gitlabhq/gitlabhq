<!--

This template is based on a model named `CoolWidget`.

To adapt this template, find and replace the following:

Template placeholders

- name: Cool Widgets
  description: the human-readable name of the model (plural)
- name: Cool Widget
  description: the human-readable name of the model (singular)
- name: cool_widgets
  description: the snake-cased name of the model (plural)
- name: cool_widget
  description: the snake-cased name of the model (singular)
- name: CoolWidget
  description: the ActiveRecord class name of the model
- name: coolWidget
  description: the camel-cased name of the model

-->

## Replicate Cool Widgets - Repository

This issue is for implementing Geo replication and verification of Cool Widgets.

For more background, see [Geo self-service framework](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/geo/framework.md).

In order to implement and test this feature, you need to first [set up Geo locally](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/geo.md).

There are three main sections below. It is a good idea to structure your merge requests this way as well:

1. Modify database schemas to prepare to add Geo support for Cool Widgets
1. Implement Geo support of Cool Widgets behind a feature flag
1. Release Geo support of Cool Widgets

It is also a good idea to first open a proof-of-concept merge request. It can be helpful for working out kinks and getting initial support and feedback from the Geo team. As an example, see the [Proof of Concept to replicate Pipeline Artifacts](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56423).

You can look into the following example for implementing replication/verification for a new Git repository type:
- [Add snippet repository verification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56596)

### Modify database schemas to prepare to add Geo support for Cool Widgets

#### Add the registry table to track replication and verification state

Geo secondary sites have a [Geo tracking database](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/geo.md#tracking-database) independent of the main database. It is used to track the replication and verification state of all replicables. Every Model has a corresponding "registry" table in the Geo tracking database.

- [ ] Create the migration file in `ee/db/geo/migrate`:

  ```shell
  bin/rails generate migration CreateCoolWidgetRegistry --database geo
  ```

- [ ] Replace the contents of the migration file with the following. Note that we cannot add a foreign key constraint on `cool_widget_id` because the `cool_widgets` table is in a different database. The application code must handle logic such as propagating deletions.

  ```ruby
  # frozen_string_literal: true

  class CreateCoolWidgetRegistry < Gitlab::Database::Migration[2.1]
    def change
      create_table :cool_widget_registry, id: :bigserial, force: :cascade do |t|
        t.bigint :cool_widget_id, null: false
        t.datetime_with_timezone :created_at, null: false
        t.datetime_with_timezone :last_synced_at
        t.datetime_with_timezone :retry_at
        t.datetime_with_timezone :verified_at
        t.datetime_with_timezone :verification_started_at
        t.datetime_with_timezone :verification_retry_at
        t.integer :state, default: 0, null: false, limit: 2
        t.integer :verification_state, default: 0, null: false, limit: 2
        t.integer :retry_count, default: 0, limit: 2, null: false
        t.integer :verification_retry_count, default: 0, limit: 2, null: false
        t.boolean :checksum_mismatch, default: false, null: false
        t.boolean :missing_on_primary, default: false, null: false
        t.binary :verification_checksum
        t.binary :verification_checksum_mismatched
        t.text :verification_failure, limit: 255
        t.text :last_sync_failure, limit: 255

        t.index :cool_widget_id, name: :index_cool_widget_registry_on_cool_widget_id, unique: true
        t.index :retry_at
        t.index :state
        # To optimize performance of CoolWidgetRegistry.verification_failed_batch
        t.index :verification_retry_at,
          name: :cool_widget_registry_failed_verification,
          order: "NULLS FIRST",
          where: "((state = 2) AND (verification_state = 3))"
        # To optimize performance of CoolWidgetRegistry.needs_verification_count
        t.index :verification_state,
          name: :cool_widget_registry_needs_verification,
          where: "((state = 2) AND (verification_state = ANY (ARRAY[0, 3])))"
        # To optimize performance of CoolWidgetRegistry.verification_pending_batch
        t.index :verified_at,
          name: :cool_widget_registry_pending_verification,
          order: "NULLS FIRST",
          where: "((state = 2) AND (verification_state = 0))"
      end
    end
  end
  ```

- [ ] If deviating from the above example, then be sure to order columns according to [our guidelines](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/ordering_table_columns.md).

- [ ] Add the new table to the [database dictionary](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/database/database_dictionary.md) defined in [`ee/db/geo/docs/`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/db/geo/docs):

  ```yaml
  table_name: cool_widget_registry
  description: Description example
  introduced_by_url: Merge request link
  milestone: Milestone example
  feature_categories:
   - Feature category example
  classes:
   - Class example
  gitlab_schema: gitlab_geo
  ```

- [ ] Run Geo tracking database migrations:

  ```shell
  bin/rake db:migrate:geo
  ```

- [ ] Be sure to commit the relevant changes in `ee/db/geo/structure.sql` and the file under `ee/db/geo/schema_migrations`

### Add verification state to the Model

The Geo primary site needs to checksum every replicable so secondaries can verify their own checksums. To do this, Geo requires the Model to have an associated table to track verification state.

- [ ] Create the migration file in `db/migrate`:

  ```shell
  bin/rails generate migration CreateCoolWidgetStates
  ```

- [ ] Replace the contents of the migration file with:

  ```ruby
  # frozen_string_literal: true

  class CreateCoolWidgetStates < Gitlab::Database::Migration[2.1]
    VERIFICATION_STATE_INDEX_NAME = "index_cool_widget_states_on_verification_state"
    PENDING_VERIFICATION_INDEX_NAME = "index_cool_widget_states_pending_verification"
    FAILED_VERIFICATION_INDEX_NAME = "index_cool_widget_states_failed_verification"
    NEEDS_VERIFICATION_INDEX_NAME = "index_cool_widget_states_needs_verification"

    def up
      create_table :cool_widget_states do |t|
        t.datetime_with_timezone :verification_started_at
        t.datetime_with_timezone :verification_retry_at
        t.datetime_with_timezone :verified_at
        t.references :cool_widget,
          null: false,
          index: { unique: true },
          foreign_key: { on_delete: :cascade }
        t.integer :verification_state, default: 0, limit: 2, null: false
        t.integer :verification_retry_count, default: 0, limit: 2, null: false
        t.binary :verification_checksum, using: 'verification_checksum::bytea'
        t.text :verification_failure, limit: 255

        t.index :verification_state, name: VERIFICATION_STATE_INDEX_NAME
        t.index :verified_at,
          where: "(verification_state = 0)",
          order: { verified_at: 'ASC NULLS FIRST' },
          name: PENDING_VERIFICATION_INDEX_NAME
        t.index :verification_retry_at,
          where: "(verification_state = 3)",
          order: { verification_retry_at: 'ASC NULLS FIRST' },
          name: FAILED_VERIFICATION_INDEX_NAME
        t.index :verification_state,
          where: "(verification_state = 0 OR verification_state = 3)",
          name: NEEDS_VERIFICATION_INDEX_NAME
      end
    end

    def down
      drop_table :cool_widget_states
    end
  end
  ```

- [ ] If deviating from the above example, then be sure to order columns according to [our guidelines](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/ordering_table_columns.md).

- [ ] If `cool_widgets` is a high-traffic table, follow [the database documentation to use `with_lock_retries`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/migration_style_guide.md#when-to-use-the-helper-method)

- [ ] Add the new table to the [database dictionary](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/database/database_dictionary.md) defined in [`db/docs/`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/db/docs):

  ```yaml
  ---
  table_name: cool_widget_states
  description: Separate table for Cool Widget verification states
  introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/XXXXX
  milestone: 'XX.Y'
  feature_categories:
   - geo_replication
  classes:
   - Geo::CoolWidgetState
  gitlab_schema: gitlab_main
  ```

- [ ] Run database migrations:

  ```shell
  bin/rake db:migrate
  ```

- [ ] Be sure to commit the relevant changes in `db/structure.sql` and the file under `db/schema_migrations`

That's all of the required database changes.

### Implement Geo support of Cool Widgets behind a feature flag

#### Step 1. Implement replication and verification

- [ ] Add the following lines to the `cool_widget` model to accomplish some important tasks:
  - Include `::Geo::ReplicableModel` in the `CoolWidget` class, and specify the Replicator class `with_replicator Geo::CoolWidgetReplicator`.
  - Include the `::Geo::VerifiableModel` concern.
  - Delegate verification related methods to the `cool_widget_state` model.
  - For verification, override some scopes to use the `cool_widget_states` table instead of the model table.
  - Implement the `verification_state_object` method to return the object that holds
    the verification details
  - Override some methods to use the `cool_widget_states` table in verification-related queries.

  Pay some attention to method `pool_repository`. Not every repository type uses repository pooling. As Geo prefers to use repository snapshotting, it can lead to data loss. Make sure to overwrite `pool_repository` so it returns nil for repositories that do not have pools.

  At this point the `CoolWidget` class should look like this:

  ```ruby
  # frozen_string_literal: true

  class CoolWidget < ApplicationRecord
    ...
    include ::Geo::ReplicableModel
    include ::Geo::VerifiableModel

    delegate(*::Geo::VerificationState::VERIFICATION_METHODS, to: :cool_widget_state)

    with_replicator Geo::CoolWidgetReplicator

    has_one :cool_widget_state, autosave: false, inverse_of: :cool_widget, class_name: 'Geo::CoolWidgetState'

    after_save :save_verification_details

    # Override the `all` default if not all records can be replicated. For an
    # example of an existing Model that needs to do this, see
    # `EE::MergeRequestDiff`.
    # scope :available_replicables, -> { all }

    scope :available_verifiables, -> { joins(:cool_widget_state) }

    scope :checksummed, -> {
      joins(:cool_widget_state).where.not(cool_widget_states: { verification_checksum: nil })
    }

    scope :not_checksummed, -> {
      joins(:cool_widget_state).where(cool_widget_states: { verification_checksum: nil })
    }

    scope :with_verification_state, ->(state) {
      joins(:cool_widget_state)
        .where(cool_widget_states: { verification_state: verification_state_value(state) })
    }

    def verification_state_object
      cool_widget_state
    end
    ...

    class_methods do
      extend ::Gitlab::Utils::Override
      ...

      # @param primary_key_in [Range, CoolWidget] arg to pass to primary_key_in scope
      # @return [ActiveRecord::Relation<CoolWidget>] everything that should be synced
      #         to this node, restricted by primary key
      def replicables_for_current_secondary(primary_key_in)
        # This issue template does not help you write this method.
        #
        # This method is called only on Geo secondary sites. It is called when
        # we want to know which records to replicate. This is not easy to automate
        # because for example:
        #
        # * The "selective sync" feature allows admins to choose which namespaces
        #   to replicate, per secondary site. Most Models are scoped to a
        #   namespace, but the nature of the relationship to a namespace varies
        #   between Models.
        # * The "selective sync" feature allows admins to choose which shards to
        #   replicate, per secondary site. Repositories are associated with
        #   shards. Most blob types are not, but Project Uploads are.
        # * Remote stored replicables are not replicated, by default. But the
        #   setting `sync_object_storage` enables replication of remote stored
        #   replicables.
        #
        # Search the codebase for examples, and consult a Geo expert if needed.
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

    # Geo checks this method in FrameworkRepositorySyncService to avoid
    # snapshotting repositories using object pools
    def pool_repository
      nil
    end

    def cool_widget_state
      super || build_cool_widget_state
    end

    ...
  end
  ```

- [ ] Implement `CoolWidget.replicables_for_current_secondary` above.
- [ ] Ensure `CoolWidget.replicables_for_current_secondary` is well-tested. Search the codebase for `replicables_for_current_secondary` to find examples of parameterized table specs. You may need to add more `FactoryBot` traits.
- [ ] Add the following shared examples to `ee/spec/models/ee/cool_widget_spec.rb`:

  ```ruby
    include_examples 'a verifiable model with a separate table for verification state' do
      let(:verifiable_model_record) { build(:cool_widget) } # add extra params if needed to make sure the record is in `Geo::ReplicableModel.verifiables` scope
      let(:unverifiable_model_record) { build(:cool_widget) } # add extra params if needed to make sure the record is NOT included in `Geo::ReplicableModel.verifiables` scope
    end
  ```

- [ ] Create `ee/app/replicators/geo/cool_widget_replicator.rb`. Implement the `#repository` method which should return a `<Repository>` instance, and implement the class method `.model` to return the `CoolWidget` class:

  ```ruby
  # frozen_string_literal: true

  module Geo
    class CoolWidgetReplicator < Gitlab::Geo::Replicator
      include ::Geo::RepositoryReplicatorStrategy
      extend ::Gitlab::Utils::Override

      def self.model
        ::CoolWidget
      end

      override :verification_feature_flag_enabled?
      def self.verification_feature_flag_enabled?
        # We are adding verification at the same time as replication, so we
        # don't need to toggle verification separately from replication. When
        # the replication feature flag is off, then verification is also off
        # (see `VerifiableReplicator.verification_enabled?`)
        true
      end

      override :housekeeping_enabled?
      def self.housekeeping_enabled?
        # Remove this method if the new Git repository type supports git
        # repository housekeeping and the ::CoolWidget#git_garbage_collect_worker_klass
        # is implemented. If the data type requires any action to be performed
        # before running the housekeeping override the `before_housekeeping` method
        # (see `RepositoryReplicatorStrategy#before_housekeeping`)
        false
      end

      def repository
        model_record.repository
      end
    end
  end
  ```

- [ ] Make sure Geo push events are created. Usually it needs some change in the `app/workers/post_receive.rb` file. Example:

  ```ruby
  def replicate_cool_widget_changes(cool_widget)
    if ::Gitlab::Geo.primary?
      cool_widget.geo_handle_after_update if cool_widget
    end
  end
  ```

  See `app/workers/post_receive.rb` for more examples.

- [ ] Make sure the repository removal is also handled. You may need to add something like the following in the destroy service of the repository:

  ```ruby
  cool_widget.replicator.geo_handle_after_destroy if cool_widget.repository
  ```

- [ ] Make sure a Geo secondary site can request and download Cool Widgets on the Geo primary site. You may need to make some changes to `Gitlab::GitAccessCoolWidget`. For example, see [this change for Group-level Wikis](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54914/diffs?commit_id=0f2b36f66697b4addbc69bd377ee2818f648dd33).


- [ ] Generate the feature flag definition files by running the feature flag commands and following the command prompts:

  ```shell
  bin/feature-flag --ee geo_cool_widget_replication --type development --group 'group::geo'
  ```

- [ ] Add this replicator class to the method `replicator_classes` in
  `ee/lib/gitlab/geo.rb`:

  ```ruby
  REPLICATOR_CLASSES = [
    ::Geo::PackageFileReplicator,
    ::Geo::CoolWidgetReplicator
  ]
  ```

- [ ] Create `ee/spec/replicators/geo/cool_widget_replicator_spec.rb` and perform the necessary setup to define the `model_record` variable for the shared examples:

  ```ruby
  # frozen_string_literal: true

  require 'spec_helper'

  RSpec.describe Geo::CoolWidgetReplicator, feature_category: :geo_replication do
    let(:model_record) { build(:cool_widget) }

    include_examples 'a repository replicator'
  end
  ```

- [ ] Create `ee/app/models/geo/cool_widget_registry.rb`:

  ```ruby
  # frozen_string_literal: true

  module Geo
    class CoolWidgetRegistry < Geo::BaseRegistry
      include ::Geo::ReplicableRegistry
      include ::Geo::VerifiableRegistry

      MODEL_CLASS = ::CoolWidget
      MODEL_FOREIGN_KEY = :cool_widget_id

      belongs_to :cool_widget, class_name: 'CoolWidget'
    end
  end
  ```

- [ ] Update `REGISTRY_CLASSES` in `ee/app/workers/geo/secondary/registry_consistency_worker.rb`.
- [ ] Add a custom factory name if needed in `def model_class_factory_name` in `ee/spec/support/helpers/ee/geo_helpers.rb`.
- [ ] Update `it 'creates missing registries for each registry class'` in `ee/spec/workers/geo/secondary/registry_consistency_worker_spec.rb`.
- [ ] Add `cool_widget_registry` to `ActiveSupport::Inflector.inflections` in `config/initializers_before_autoloader/000_inflections.rb`.
- [ ] Create `ee/spec/factories/geo/cool_widget_registry.rb`:

  ```ruby
  # frozen_string_literal: true

  FactoryBot.define do
    factory :geo_cool_widget_registry, class: 'Geo::CoolWidgetRegistry' do
      cool_widget # This association should have data, like a file or repository
      state { Geo::CoolWidgetRegistry.state_value(:pending) }

      trait :synced do
        state { Geo::CoolWidgetRegistry.state_value(:synced) }
        last_synced_at { 5.days.ago }
      end

      trait :failed do
        state { Geo::CoolWidgetRegistry.state_value(:failed) }
        last_synced_at { 1.day.ago }
        retry_count { 2 }
        retry_at { 2.hours.from_now }
        last_sync_failure { 'Random error' }
      end

      trait :started do
        state { Geo::CoolWidgetRegistry.state_value(:started) }
        last_synced_at { 1.day.ago }
        retry_count { 0 }
      end

      trait :verification_succeeded do
        synced
        verification_checksum { 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef' }
        verification_state { Geo::CoolWidgetRegistry.verification_state_value(:verification_succeeded) }
        verified_at { 5.days.ago }
      end

      trait :verification_failed do
        synced
        verification_failure { 'Could not calculate the checksum' }
        verification_state { Geo::CoolWidgetRegistry.verification_state_value(:verification_failed) }
        verification_retry_count { 1 }
        verification_retry_at { 2.hours.from_now }
      end
    end
  end
  ```

- [ ] Create `ee/spec/models/geo/cool_widget_registry_spec.rb`:

  ```ruby
  # frozen_string_literal: true

  require 'spec_helper'

  RSpec.describe Geo::CoolWidgetRegistry, :geo, type: :model, feature_category: :geo_replication do
    let_it_be(:registry) { create(:geo_cool_widget_registry) }

    specify 'factory is valid' do
      expect(registry).to be_valid
    end

    include_examples 'a Geo framework registry'
  end
  ```

- [ ] Add the following to `ee/spec/factories/cool_widgets.rb`:

  ```ruby
  # frozen_string_literal: true

  FactoryBot.modify do
    factory :cool_widget do
      trait :verification_succeeded do
        repository
        verification_checksum { 'abc' }
        verification_state { CoolWidget.verification_state_value(:verification_succeeded) }
      end

      trait :verification_failed do
        repository
        verification_failure { 'Could not calculate the checksum' }
        verification_state { CoolWidget.verification_state_value(:verification_failed) }
      end
    end
  end
  ```

  If there is not an existing factory for the object in `spec/factories/cool_widgets.rb`, wrap the traits in `FactoryBot.create` instead of `FactoryBot.modify`.

- [ ] Make sure the factory also allows setting a `project` attribute. If the model does not have a direct relation to a project, you can use a `transient` attribute. Check out `spec/factories/merge_request_diffs.rb` for an example.

- [ ] Following [the example of Merge Request Diffs](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63309) add a `Geo::CoolWidgetState` model in `ee/app/models/geo/cool_widget_state.rb`:

  ``` ruby
  # frozen_string_literal: true

  module Geo
    class CoolWidgetState < ApplicationRecord
      include ::Geo::VerificationStateDefinition

      self.primary_key = :cool_widget_id

      belongs_to :cool_widget, inverse_of: :cool_widget_state

      validates :verification_state, :cool_widget, presence: true
    end
  end
  ```

- [ ] Add a `factory` for `cool_widget_state`, in `ee/spec/factories/geo/cool_widget_states.rb`:

  ``` ruby
  # frozen_string_literal: true

  FactoryBot.define do
    factory :geo_cool_widget_state, class: 'Geo::CoolWidgetState' do
      cool_widget

      trait :checksummed do
        verification_checksum { 'abc' }
      end

      trait :checksum_failure do
        verification_failure { 'Could not calculate the checksum' }
      end
    end
  end
  ```


#### Step 2. Implement metrics gathering

Metrics are gathered by `Geo::MetricsUpdateWorker`, persisted in `GeoNodeStatus` for display in the UI, and sent to Prometheus:

- [ ] Add the following fields to Geo Node Status example responses in `doc/api/geo_nodes.md`:
  - `cool_widgets_count`
  - `cool_widgets_checksum_total_count`
  - `cool_widgets_checksummed_count`
  - `cool_widgets_checksum_failed_count`
  - `cool_widgets_synced_count`
  - `cool_widgets_failed_count`
  - `cool_widgets_registry_count`
  - `cool_widgets_verification_total_count`
  - `cool_widgets_verified_count`
  - `cool_widgets_verification_failed_count`
  - `cool_widgets_synced_in_percentage`
  - `cool_widgets_verified_in_percentage`
- [ ] Add the same fields to `GET /geo_nodes/status` example response in
  `ee/spec/fixtures/api/schemas/public_api/v4/geo_node_status.json` and `ee/spec/fixtures/api/schemas/public_api/v4/geo_site_status.json`.
- [ ] Add the following fields to the `Sidekiq metrics` table in `doc/administration/monitoring/prometheus/gitlab_metrics.md`:
  ```markdown
  | `geo_cool_widgets` | Gauge | XX.Y | Number of Cool Widgets on primary | `url` |
  | `geo_cool_widgets_checksum_total` | Gauge | XX.Y | Number of Cool Widgets to checksum on primary | `url` |
  | `geo_cool_widgets_checksummed` | Gauge | XX.Y | Number of Cool Widgets that successfully calculated the checksum on primary | `url` |
  | `geo_cool_widgets_checksum_failed` | Gauge | XX.Y | Number of Cool Widgets that failed to calculate the checksum on primary | `url` |
  | `geo_cool_widgets_synced` | Gauge | XX.Y | Number of syncable Cool Widgets synced on secondary | `url` |
  | `geo_cool_widgets_failed` | Gauge | XX.Y | Number of syncable Cool Widgets failed to sync on secondary | `url` |
  | `geo_cool_widgets_registry` | Gauge | XX.Y | Number of Cool Widgets in the registry | `url` |
  | `geo_cool_widgets_verification_total` | Gauge | XX.Y | Number of Cool Widgets to attempt to verify on secondary | `url` |
  | `geo_cool_widgets_verified` | Gauge | XX.Y | Number of Cool Widgets successfully verified on secondary | `url` |
  | `geo_cool_widgets_verification_failed` | Gauge | XX.Y | Number of Cool Widgets that failed verification on secondary | `url` |
  ```
- [ ] Run the rake task `geo:dev:ssf_metrics` and commit the changes to `ee/config/metrics/object_schemas/geo_node_usage.json`

Cool Widget replication and verification metrics should now be available in the API, the `Admin > Geo > Sites` view, and Prometheus.

#### Step 3. Implement the GraphQL API

The GraphQL API is used by `Admin > Geo > Replication Details` views, and is directly queryable by administrators.

- [ ] Add a new field to `GeoNodeType` in `ee/app/graphql/types/geo/geo_node_type.rb`:

  ```ruby
  field :cool_widget_registries, ::Types::Geo::CoolWidgetRegistryType.connection_type,
        null: true,
        resolver: ::Resolvers::Geo::CoolWidgetRegistriesResolver,
        description: 'Find Cool Widget registries on this Geo node. '\
                     'Ignored if `geo_cool_widget_replication` feature flag is disabled.',
        experiment: { milestone: '15.5' } # Update the milestone
  ```

- [ ] Add the new `cool_widget_registries` field name to the `expected_fields` array in `ee/spec/graphql/types/geo/geo_node_type_spec.rb`.
- [ ] Create `ee/app/graphql/resolvers/geo/cool_widget_registries_resolver.rb`:

  ```ruby
  # frozen_string_literal: true

  module Resolvers
    module Geo
      class CoolWidgetRegistriesResolver < BaseResolver
        type ::Types::Geo::GeoNodeType.connection_type, null: true

        include RegistriesResolver
      end
    end
  end
  ```

- [ ] Create `ee/spec/graphql/resolvers/geo/cool_widget_registries_resolver_spec.rb`:

  ```ruby
  # frozen_string_literal: true

  require 'spec_helper'

  RSpec.describe Resolvers::Geo::CoolWidgetRegistriesResolver, feature_category: :geo_replication do
    it_behaves_like 'a Geo registries resolver', :geo_cool_widget_registry
  end
  ```

- [ ] Create `ee/app/finders/geo/cool_widget_registry_finder.rb`:

  ```ruby
  # frozen_string_literal: true

  module Geo
    class CoolWidgetRegistryFinder
      include FrameworkRegistryFinder
    end
  end
  ```

- [ ] Create `ee/spec/finders/geo/cool_widget_registry_finder_spec.rb`:

  ```ruby
  # frozen_string_literal: true

  require 'spec_helper'

  RSpec.describe Geo::CoolWidgetRegistryFinder, feature_category: :geo_replication do
    it_behaves_like 'a framework registry finder', :geo_cool_widget_registry
  end
  ```

- [ ] Create `ee/app/graphql/types/geo/cool_widget_registry_type.rb`:

  ```ruby
  # frozen_string_literal: true

  module Types
    module Geo
      # rubocop:disable Graphql/AuthorizeTypes -- because it is included
      class CoolWidgetRegistryType < BaseObject
        graphql_name 'CoolWidgetRegistry'

        include ::Types::Geo::RegistryType

        description 'Represents the Geo replication and verification state of a cool_widget'

        field :cool_widget_id, GraphQL::Types::ID, null: false, description: 'ID of the Cool Widget.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
  ```

- [ ] Create `ee/spec/graphql/types/geo/cool_widget_registry_type_spec.rb`:

  ```ruby
  # frozen_string_literal: true

  require 'spec_helper'

  RSpec.describe GitlabSchema.types['CoolWidgetRegistry'], feature_category: :geo_replication do
    it_behaves_like 'a Geo registry type'

    it 'has the expected fields (other than those included in RegistryType)' do
      expected_fields = %i[cool_widget_id]

      expect(described_class).to have_graphql_fields(*expected_fields).at_least
    end
  end
  ```

- [ ] Add integration tests for providing CoolWidget registry data to the frontend via the GraphQL API, by duplicating and modifying the following shared examples in `ee/spec/requests/api/graphql/geo/registries_spec.rb`:

  ```ruby
  it_behaves_like 'gets registries for', {
    field_name: 'coolWidgetRegistries',
    registry_class_name: 'CoolWidgetRegistry',
    registry_factory: :geo_cool_widget_registry,
    registry_foreign_key_field_name: 'coolWidgetId'
  }
  ```

To allow the new replicable to resync and reverify via GraphQL:

- [ ] Add the `CoolWidgetRegistryType` to the `GEO_REGISTRY_TYPE` constant in `ee/app/graphql/types/geo/registrable_type.rb`:

  ```ruby
    GEO_REGISTRY_TYPES = {
      ::Geo::CoolWidgetRegistry => Types::Geo::CoolWidgetRegistryType
    }
  ```

- [ ] Include the `CoolWidgetRegistry` in the `let(:registry_classes)` variable of `ee/spec/graphql/types/geo/registry_class_enum_spec.rb`:

  ```ruby
    let(:registry_classes) do
      %w[
       COOL_WIDGET_REGISTRY
      ]
    end
  ```

- [ ] Include the new registry in the Rspec parameterized table of `ee/spec/support/shared_contexts/graphql/geo/registries_shared_context.rb`:

  ```ruby
     # frozen_string_literal: true

     RSpec.shared_context 'with geo registries shared context' do
       using RSpec::Parameterized::TableSyntax

       where(:registry_class, :registry_type, :registry_factory) do
         Geo::CoolWidgetRegistry | Types::Geo::CoolWidgetRegistryType | :geo_cool_widget_registry
       end
     end
  ```

- [ ] Update the GraphQL reference documentation:

  ```shell
  bundle exec rake gitlab:graphql:compile_docs
  ```

Individual Cool Widget replication and verification data should now be available via the GraphQL API.

#### Step 4. Handle batch destroy

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

- [ ] Include a comment mentioning that the change is based on a documented template.
- [ ] `replicables_for_current_secondary` and `available_replicables` may differ per Model. If their queries are new, then add [query plans](https://docs.gitlab.com/ee/development/database_review.html#query-plans) to the MR description. An easy place to gather SQL queries is your GDK's `log/test.log` when running tests of these methods.

### Release Geo support of Cool Widgets

- [ ] In the rollout issue you created when creating the feature flag, modify the Roll Out Steps:
  - [ ] Cross out any steps related to testing on production GitLab.com, because Geo is not running on production GitLab.com at the moment.
  - [ ] Add a step to `Test replication and verification of Cool Widgets on a non-GDK-deployment. For example, using GitLab Environment Toolkit`.
  - [ ] Add a step to `Ping the Geo PM and EM to coordinate testing`. For example, you might add steps to generate Cool Widgets, and then a Geo engineer may take it from there.
- [ ] In `ee/config/feature_flags/development/geo_cool_widget_replication.yml`, set `default_enabled: true`
- [ ] In `ee/app/graphql/types/geo/geo_node_type.rb`, remove the `alpha` option for the released type:

  ```ruby
  field :cool_widget_registries, ::Types::Geo::CoolWidgetRegistryType.connection_type,
        null: true,
        resolver: ::Resolvers::Geo::CoolWidgetRegistriesResolver,
        description: 'Find Cool Widget registries on this Geo node. '\
                     'Ignored if `geo_cool_widget_replication` feature flag is disabled.',
        experiment: { milestone: '15.5' } # Update the milestone
  ```

- [ ] Run `bundle exec rake gitlab:graphql:compile_docs` after the step above to regenerate the GraphQL docs.

- [ ] Add a row for Cool Widgets to the `Data types` table in [Geo data types support](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/geo/replication/datatypes.md#data-types)
- [ ] Add a row for Cool Widgets to the `Limitations on replication/verification` table in [Geo data types support](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/geo/replication/datatypes.md#limitations-on-replicationverification). If the row already exists, then update it to show that Replication and Verification is released in the current version.
