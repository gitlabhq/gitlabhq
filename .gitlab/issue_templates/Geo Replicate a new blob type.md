<!--

This template is based on a model named `CoolWidget`.

To adapt this template, find and replace the following tokens:

- `CoolWidget`
- `Cool Widget`
- `cool_widget`
- `coolWidget`

If your Model's pluralized form is non-standard, i.e. it doesn't just end in `s`, find and replace the following tokens *first*:

- `CoolWidgets`
- `Cool Widgets`
- `cool_widgets`
- `coolWidgets`

-->

## Replicate Cool Widgets

This issue is for implementing Geo replication and verification of Cool Widgets.

For more background, see [Geo self-service framework](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/geo/framework.md).

In order to implement and test this feature, you need to first [set up Geo locally](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/geo.md).

There are three main sections below. It is a good idea to structure your merge requests this way as well:

1. Modify database schemas to prepare to add Geo support for Cool Widgets
1. Implement Geo support of Cool Widgets behind a feature flag
1. Release Geo support of Cool Widgets

It is also a good idea to first open a proof-of-concept merge request. It can be helpful for working out kinks and getting initial support and feedback from the Geo team. As an example, see the [Proof of Concept to replicate Pipeline Artifacts](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56423).

You can look into the following examples of MRs for implementing replication/verification for a new blob type:
- [Add db changes](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60935) and [add verification for MR diffs using SSF](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63309)
- [Verify Terraform state versions](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58800)

### Modify database schemas to prepare to add Geo support for Cool Widgets

You might do this section in its own merge request, but it is not required.

#### Add the registry table to track replication and verification state

Geo secondary sites have a [Geo tracking database](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/geo.md#tracking-database) independent of the main database. It is used to track the replication and verification state of all replicables. Every Model has a corresponding "registry" table in the Geo tracking database.

- [ ] Create the migration file in `ee/db/geo/migrate`:

  ```shell
  bin/rails generate geo_migration CreateCoolWidgetRegistry
  ```

- [ ] Replace the contents of the migration file with the following. Note that we cannot add a foreign key constraint on `cool_widget_id` because the `cool_widgets` table is in a different database. The application code must handle logic such as propagating deletions.

  ```ruby
  # frozen_string_literal: true

  class CreateCoolWidgetRegistry < ActiveRecord::Migration[6.0]
    include Gitlab::Database::MigrationHelpers

    disable_ddl_transaction!

    def up
      unless table_exists?(:cool_widget_registry)
        ActiveRecord::Base.transaction do
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
            t.binary :verification_checksum
            t.binary :verification_checksum_mismatched
            t.string :verification_failure, limit: 255 # rubocop:disable Migration/PreventStrings see https://gitlab.com/gitlab-org/gitlab/-/issues/323806
            t.string :last_sync_failure, limit: 255 # rubocop:disable Migration/PreventStrings see https://gitlab.com/gitlab-org/gitlab/-/issues/323806

            t.index :cool_widget_id, name: :index_cool_widget_registry_on_cool_widget_id, unique: true
            t.index :retry_at
            t.index :state
            # To optimize performance of CoolWidgetRegistry.verification_failed_batch
            t.index :verification_retry_at, name:  :cool_widget_registry_failed_verification, order: "NULLS FIRST",  where: "((state = 2) AND (verification_state = 3))"
            # To optimize performance of CoolWidgetRegistry.needs_verification_count
            t.index :verification_state, name:  :cool_widget_registry_needs_verification, where: "((state = 2)  AND (verification_state = ANY (ARRAY[0, 3])))"
            # To optimize performance of CoolWidgetRegistry.verification_pending_batch
            t.index :verified_at, name: :cool_widget_registry_pending_verification, order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 0))"
          end
        end
      end
    end

    def down
      drop_table :cool_widget_registry
    end
  end
  ```

- [ ] If deviating from the above example, then be sure to order columns according to [our guidelines](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/ordering_table_columns.md).
- [ ] Run Geo tracking database migrations:

  ```shell
  bin/rake geo:db:migrate
  ```

- [ ] Be sure to commit the relevant changes in `ee/db/geo/schema.rb`

### Add verification state fields on the Geo primary site

The Geo primary site needs to checksum every replicable in order for secondaries to verify their own checksums. To do this, Geo requires fields on the Model. There are two ways to add the necessary verification state fields. If the table is large and wide, then it may be a good idea to add verification state fields to a separate table (Option 2). Consult a database expert if needed.

#### Add verification state fields to the model table (Option 1)

- [ ] Create the migration file in `db/migrate`:

  ```shell
  bin/rails generate migration AddVerificationStateToCoolWidgets
  ```

- [ ] Replace the contents of the migration file with:

  ```ruby
  # frozen_string_literal: true

  class AddVerificationStateToCoolWidgets < ActiveRecord::Migration[6.0]
    def change
      change_table(:cool_widgets) do |t|
        t.integer :verification_state, default: 0, limit: 2, null: false
        t.column :verification_started_at, :datetime_with_timezone
        t.integer :verification_retry_count, limit: 2, null: false
        t.column :verification_retry_at, :datetime_with_timezone
        t.column :verified_at, :datetime_with_timezone
        t.binary :verification_checksum, using: 'verification_checksum::bytea'

        t.text :verification_failure # rubocop:disable Migration/AddLimitToTextColumns
      end
    end
  end
  ```

- [ ] If deviating from the above example, then be sure to order columns according to [our guidelines](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/ordering_table_columns.md).
- [ ] If `cool_widgets` is a high-traffic table, follow [the database documentation to use `with_lock_retries`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/migration_style_guide.md#when-to-use-the-helper-method)
- [ ] Adding a `text` column also [requires](../database/strings_and_the_text_data_type.md#add-a-text-column-to-an-existing-table) setting a limit. Create the migration file in `db/migrate`:

  ```shell
  bin/rails generate migration AddVerificationFailureLimitToCoolWidgets
  ```

- [ ] Replace the contents of the migration file with:

  ```ruby
  # frozen_string_literal: true

  class AddVerificationFailureLimitToCoolWidgets < ActiveRecord::Migration[6.0]
    include Gitlab::Database::MigrationHelpers

    disable_ddl_transaction!

    CONSTRAINT_NAME = 'cool_widget_verification_failure_text_limit'

    def up
      add_text_limit :cool_widget, :verification_failure, 255, constraint_name: CONSTRAINT_NAME
    end

    def down
      remove_check_constraint(:cool_widget, CONSTRAINT_NAME)
    end
  end
  ```

- [ ] Add indexes on verification fields to ensure verification can be performed efficiently. Some or all of these indexes can be omitted if the table is guaranteed to be small. Ask a database expert if you are considering omitting indexes. Create the migration file in `db/migrate`:

  ```shell
  bin/rails generate migration AddVerificationIndexesToCoolWidgets
  ```

- [ ] Replace the contents of the migration file with:

  ```ruby
  # frozen_string_literal: true

  class AddVerificationIndexesToCoolWidgets < ActiveRecord::Migration[6.0]
    include Gitlab::Database::MigrationHelpers

    VERIFICATION_STATE_INDEX_NAME = "index_cool_widgets_on_verification_state"
    PENDING_VERIFICATION_INDEX_NAME = "index_cool_widgets_pending_verification"
    FAILED_VERIFICATION_INDEX_NAME = "index_cool_widgets_failed_verification"
    NEEDS_VERIFICATION_INDEX_NAME = "index_cool_widgets_needs_verification"

    disable_ddl_transaction!

    def up
      add_concurrent_index :cool_widgets, :verification_state, name: VERIFICATION_STATE_INDEX_NAME
      add_concurrent_index :cool_widgets, :verified_at, where: "(verification_state = 0)", order: { verified_at: 'ASC NULLS FIRST' }, name: PENDING_VERIFICATION_INDEX_NAME
      add_concurrent_index :cool_widgets, :verification_retry_at, where: "(verification_state = 3)", order: { verification_retry_at: 'ASC NULLS FIRST' }, name: FAILED_VERIFICATION_INDEX_NAME
      add_concurrent_index :cool_widgets, :verification_state, where: "(verification_state = 0 OR verification_state = 3)", name: NEEDS_VERIFICATION_INDEX_NAME
    end

    def down
      remove_concurrent_index_by_name :cool_widgets, VERIFICATION_STATE_INDEX_NAME
      remove_concurrent_index_by_name :cool_widgets, PENDING_VERIFICATION_INDEX_NAME
      remove_concurrent_index_by_name :cool_widgets, FAILED_VERIFICATION_INDEX_NAME
      remove_concurrent_index_by_name :cool_widgets, NEEDS_VERIFICATION_INDEX_NAME
    end
  end
  ```

- [ ] Run database migrations:

  ```shell
  bin/rake db:migrate
  ```

- [ ] Be sure to commit the relevant changes in `db/structure.sql`

#### Add verification state fields to a separate table (Option 2)

- [ ] Create the migration file in `db/migrate`:

  ```shell
  bin/rails generate migration CreateCoolWidgetStates
  ```

- [ ] Replace the contents of the migration file with:

  ```ruby
  # frozen_string_literal: true

  class CreateCoolWidgetStates < ActiveRecord::Migration[6.0]
    include Gitlab::Database::MigrationHelpers

    VERIFICATION_STATE_INDEX_NAME = "index_cool_widget_states_on_verification_state"
    PENDING_VERIFICATION_INDEX_NAME = "index_cool_widget_states_pending_verification"
    FAILED_VERIFICATION_INDEX_NAME = "index_cool_widget_states_failed_verification"
    NEEDS_VERIFICATION_INDEX_NAME = "index_cool_widget_states_needs_verification"

    disable_ddl_transaction!

    def up
      unless table_exists?(:cool_widget_states)
        with_lock_retries do
          create_table :cool_widget_states, id: false do |t|
            t.references :cool_widget, primary_key: true, null: false, foreign_key: { on_delete: :cascade }
            t.integer :verification_state, default: 0, limit: 2, null: false
            t.column :verification_started_at, :datetime_with_timezone
            t.datetime_with_timezone :verification_retry_at
            t.datetime_with_timezone :verified_at
            t.integer :verification_retry_count, limit: 2
            t.binary :verification_checksum, using: 'verification_checksum::bytea'
            t.text :verification_failure

            t.index :verification_state, name: VERIFICATION_STATE_INDEX_NAME
            t.index :verified_at, where: "(verification_state = 0)", order: { verified_at: 'ASC NULLS FIRST' }, name: PENDING_VERIFICATION_INDEX_NAME
            t.index :verification_retry_at, where: "(verification_state = 3)", order: { verification_retry_at: 'ASC NULLS FIRST' }, name: FAILED_VERIFICATION_INDEX_NAME
            t.index :verification_state, where: "(verification_state = 0 OR verification_state = 3)", name: NEEDS_VERIFICATION_INDEX_NAME
          end
        end
      end

      add_text_limit :cool_widget_states, :verification_failure, 255
    end

    def down
      drop_table :cool_widget_states
    end
  end
  ```

- [ ] If deviating from the above example, then be sure to order columns according to [our guidelines](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/ordering_table_columns.md).
- [ ] Run database migrations:

  ```shell
  bin/rake db:migrate
  ```

- [ ] Be sure to commit the relevant changes in `db/structure.sql`

That's all of the required database changes.

### Implement Geo support of Cool Widgets behind a feature flag

#### Step 1. Implement replication and verification

- [ ] Include `Gitlab::Geo::ReplicableModel` in the `CoolWidget` class, and specify the Replicator class `with_replicator Geo::CoolWidgetReplicator`.

  At this point the `CoolWidget` class should look like this:

  ```ruby
  # frozen_string_literal: true

  class CoolWidget < ApplicationRecord
    include ::Gitlab::Geo::ReplicableModel
    include ::Gitlab::Geo::VerificationState

    with_replicator Geo::CoolWidgetReplicator

    mount_uploader :file, CoolWidgetUploader

    # Override the `all` default if not all records can be replicated. For an
    # example of an existing Model that needs to do this, see
    # `EE::MergeRequestDiff`.
    # scope :available_replicables, -> { all }

    # @param primary_key_in [Range, CoolWidget] arg to pass to primary_key_in scope
    # @return [ActiveRecord::Relation<CoolWidget>] everything that should be synced to this node, restricted by primary key
    def self.replicables_for_current_secondary(primary_key_in)
      # This issue template does not help you write this method.
      #
      # This method is called only on Geo secondary sites. It is called when
      # we want to know which records to replicate. This is not easy to automate
      # because for example:
      #
      # * The "selective sync" feature allows admins to choose which namespaces #   to replicate, per secondary site. Most Models are scoped to a
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
    ...
  end
  ```

- [ ] Implement `CoolWidget.replicables_for_current_secondary` above.
- [ ] Ensure `CoolWidget.replicables_for_current_secondary` is well-tested. Search the codebase for `replicables_for_current_secondary` to find examples of parameterized table specs. You may need to add more `FactoryBot` traits.
- [ ] Create `ee/app/replicators/geo/cool_widget_replicator.rb`. Implement the `#carrierwave_uploader` method which should return a `CarrierWave::Uploader`, and implement the class method `.model` to return the `CoolWidget` class:

  ```ruby
  # frozen_string_literal: true

  module Geo
    class CoolWidgetReplicator < Gitlab::Geo::Replicator
      include ::Geo::BlobReplicatorStrategy
      extend ::Gitlab::Utils::Override

      def self.model
        ::CoolWidget
      end

      def carrierwave_uploader
        model_record.file
      end

      # The feature flag follows the format `geo_#{replicable_name}_replication`,
      # so here it would be `geo_cool_widget_replication`
      def self.replication_enabled_by_default?
        false
      end

      override :verification_feature_flag_enabled?
      def self.verification_feature_flag_enabled?
        # We are adding verification at the same time as replication, so we
        # don't need to toggle verification separately from replication. When
        # the replication feature flag is off, then verification is also off
        # (see `VerifiableReplicator.verification_enabled?`)
        true
      end

    end
  end
  ```

- [ ] Generate the feature flag definition file by running the feature flag command and following the command prompts:

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
  end
  ```

- [ ] Create `ee/spec/replicators/geo/cool_widget_replicator_spec.rb` and perform the necessary setup to define the `model_record` variable for the shared examples:

  ```ruby
  # frozen_string_literal: true

  require 'spec_helper'

  RSpec.describe Geo::CoolWidgetReplicator do
    let(:model_record) { build(:cool_widget) }

    include_examples 'a blob replicator'
    include_examples 'a verifiable replicator'
  end
  ```

- [ ] Create `ee/app/models/geo/cool_widget_registry.rb`:

  ```ruby
  # frozen_string_literal: true

  class Geo::CoolWidgetRegistry < Geo::BaseRegistry
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry

    MODEL_CLASS = ::CoolWidget
    MODEL_FOREIGN_KEY = :cool_widget_id

    belongs_to :cool_widget, class_name: 'CoolWidget'
  end
  ```

- [ ] Update `REGISTRY_CLASSES` in `ee/app/workers/geo/secondary/registry_consistency_worker.rb`.
- [ ] Update `def model_class_factory_name` in `ee/spec/services/geo/registry_consistency_service_spec.rb`.
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
        last_sync_failure { 'Random error' }
      end

      trait :started do
        state { Geo::CoolWidgetRegistry.state_value(:started) }
        last_synced_at { 1.day.ago }
        retry_count { 0 }
      end

      trait :verification_succeeded do
        verification_checksum { 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef' }
        verification_state { Geo::CoolWidgetRegistry.verification_state_value(:verification_succeeded) }
        verified_at { 5.days.ago }
      end
    end
  end
  ```

- [ ] Create `ee/spec/models/geo/cool_widget_registry_spec.rb`:

  ```ruby
  # frozen_string_literal: true

  require 'spec_helper'

  RSpec.describe Geo::CoolWidgetRegistry, :geo, type: :model do
    let_it_be(:registry) { create(:geo_cool_widget_registry) }

    specify 'factory is valid' do
      expect(registry).to be_valid
    end

    include_examples 'a Geo framework registry'
    include_examples 'a Geo verifiable registry'
  end
  ```

- [ ] Add the following to `spec/factories/cool_widgets.rb`:

  ```ruby
  trait(:verification_succeeded) do
    with_file
    verification_checksum { 'abc' }
    verification_state { CoolWidget.verification_state_value(:verification_succeeded) }
  end

  trait(:verification_failed) do
    with_file
    verification_failure { 'Could not calculate the checksum' }
    verification_state { CoolWidget.verification_state_value(:verification_failed) }
  end
  ```

- [ ] Make sure the factory also allows setting a `project` attribute. If the model does not have a direct relation to a project, you can use a `transient` attribute. Check out `spec/factories/merge_request_diffs.rb` for an example.

##### If you added verification state fields to a separate table (option 2 above), then you need to make additional model and factory changes

If you did not add verification state fields to a separate table, `cool_widget_states`, then skip to [Step 2. Implement metrics gathering](#step-2-implement-metrics-gathering).

Otherwise, you can follow [the example of Merge Request Diffs](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63309).

- [ ] Add a `Geo::CoolWidgetState` model in `ee/app/models/ee/geo/cool_widget_state.rb`:

  ``` ruby
  module Geo
    class CoolWidgetState < ApplicationRecord
      self.primary_key = :cool_widget_id

      belongs_to :cool_widget, inverse_of: :cool_widget_state
    end
  end
  ```

- [ ] Add a `factory` for `cool_widget_state`, in `ee/spec/factories/geo/cool_widget_states.rb`:

  ``` ruby
  # frozen_string_literal: true

  FactoryBot.define do
    factory :geo_cool_widget_state, class: 'Geo::CoolWidgetState' do
      cool_widget

      trait(:checksummed) do
        verification_checksum { 'abc' }
      end

      trait(:checksum_failure) do
        verification_failure { 'Could not calculate the checksum' }
      end
    end
  end
  ```

- [ ] Add the following lines to the `cool_widget` model to accomplish some important tasks:
  - Include the `::Gitlab::Geo::VerificationState` concern.
  - Delegate verification related methods to the `cool_widget_state` model.
  - Override some scopes to use the `cool_widget_states` table instead of the model table, for verification.
  - Override some methods to use the `cool_widget_states` table in verification related queries.

  ```ruby
  class CoolWidget < ApplicationRecord
    ...
    include ::Gitlab::Geo::VerificationState

    has_one :cool_widget_state, autosave: true, inverse_of: :cool_widget, class_name: 'Geo::CoolWidgetState'

    delegate :verification_retry_at, :verification_retry_at=,
             :verified_at, :verified_at=,
             :verification_checksum, :verification_checksum=,
             :verification_failure, :verification_failure=,
             :verification_retry_count, :verification_retry_count=,
             :verification_state=, :verification_state,
             :verification_started_at=, :verification_started_at,
             to: :cool_widget_state
    ...

    scope :with_verification_state, ->(state) { joins(:cool_widget_state).where(cool_widget_states: { verification_state: verification_state_value(state) }) }
    scope :checksummed, -> { joins(:cool_widget_state).where.not(cool_widget_states: { verification_checksum: nil } ) }
    scope :not_checksummed, -> { joins(:cool_widget_state).where(cool_widget_states: { verification_checksum: nil } ) }

    ...

    class_methods do
      extend ::Gitlab::Utils::Override
      ...
      override :verification_state_table_name
      def verification_state_table_name
        'cool_widget_states'
      end

      override :verification_state_model_key
      def verification_state_model_key
        'cool_widget_id'
      end

      override :verification_arel_table
      def verification_arel_table
        CoolWidgetState.arel_table
      end
    end
    ...

    def cool_widget_state
      super || build_cool_widget_state
    end

    ...
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
  `ee/spec/fixtures/api/schemas/public_api/v4/geo_node_status.json`.
- [ ] Add the following fields to the `Sidekiq metrics` table in `doc/administration/monitoring/prometheus/gitlab_metrics.md`:
  - `geo_cool_widgets`
  - `geo_cool_widgets_checksum_total`
  - `geo_cool_widgets_checksummed`
  - `geo_cool_widgets_checksum_failed`
  - `geo_cool_widgets_synced`
  - `geo_cool_widgets_failed`
  - `geo_cool_widgets_registry`
  - `geo_cool_widgets_verification_total`
  - `geo_cool_widgets_verified`
  - `geo_cool_widgets_verification_failed`
- [ ] Add the following to the parameterized table in the `context 'Replicator stats' do` block in `ee/spec/models/geo_node_status_spec.rb`:

  ```ruby
  Geo::CoolWidgetReplicator | :cool_widget | :geo_cool_widget_registry
  ```

Cool Widget replication and verification metrics should now be available in the API, the `Admin > Geo > Nodes` view, and Prometheus.

#### Step 3. Implement the GraphQL API

The GraphQL API is used by `Admin > Geo > Replication Details` views, and is directly queryable by administrators.

- [ ] Add a new field to `GeoNodeType` in `ee/app/graphql/types/geo/geo_node_type.rb`:

  ```ruby
  field :cool_widget_registries, ::Types::Geo::CoolWidgetRegistryType.connection_type,
        null: true,
        resolver: ::Resolvers::Geo::CoolWidgetRegistriesResolver,
        description: 'Find Cool Widget registries on this Geo node',
        feature_flag: :geo_cool_widget_replication
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

  RSpec.describe Resolvers::Geo::CoolWidgetRegistriesResolver do
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

  RSpec.describe Geo::CoolWidgetRegistryFinder do
    it_behaves_like 'a framework registry finder', :geo_cool_widget_registry
  end
  ```

- [ ] Create `ee/app/graphql/types/geo/cool_widget_registry_type.rb`:

  ```ruby
  # frozen_string_literal: true

  module Types
    module Geo
      # rubocop:disable Graphql/AuthorizeTypes because it is included
      class CoolWidgetRegistryType < BaseObject
        include ::Types::Geo::RegistryType

        graphql_name 'CoolWidgetRegistry'
        description 'Represents the Geo replication and verification state of a cool_widget'

        field :cool_widget_id, GraphQL::ID_TYPE, null: false, description: 'ID of the Cool Widget'
      end
    end
  end
  ```

- [ ] Create `ee/spec/graphql/types/geo/cool_widget_registry_type_spec.rb`:

  ```ruby
  # frozen_string_literal: true

  require 'spec_helper'

  RSpec.describe GitlabSchema.types['CoolWidgetRegistry'] do
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

- [ ] Update the GraphQL reference documentation:

  ```shell
  bundle exec rake gitlab:graphql:compile_docs
  ```

Individual Cool Widget replication and verification data should now be available via the GraphQL API.

### Release Geo support of Cool Widgets

- [ ] In the rollout issue you created when creating the feature flag, modify the Roll Out Steps:
  - [ ] Cross out any steps related to testing on production GitLab.com, because Geo is not running on production GitLab.com at the moment.
  - [ ] Add a step to `Test replication and verification of Cool Widgets on a non-GDK-deployment. For example, using GitLab Environment Toolkit`.
  - [ ] Add a step to `Ping the Geo PM and EM to coordinate testing`. For example, you might add steps to generate Cool Widgets, and then a Geo engineer may take it from there.
- [ ] In `ee/config/feature_flags/development/geo_cool_widget_replication.yml`, set `default_enabled: true`

- [ ] In `ee/app/replicators/geo/cool_widget_replicator.rb`, delete the `self.replication_enabled_by_default?` method:

  ```ruby
  module Geo
    class CoolWidgetReplicator < Gitlab::Geo::Replicator
      ...
      # REMOVE THIS LINE IF IT IS NO LONGER NEEDED
      extend ::Gitlab::Utils::Override

      ...
      # REMOVE THIS METHOD
      def self.replication_enabled_by_default?
        false
      end
      # REMOVE THIS METHOD

      ...
    end
  end
  ```

- [ ] In `ee/app/graphql/types/geo/geo_node_type.rb`, remove the `feature_flag` option for the released type:

  ```ruby
  field :cool_widget_registries, ::Types::Geo::CoolWidgetRegistryType.connection_type,
        null: true,
        resolver: ::Resolvers::Geo::CoolWidgetRegistriesResolver,
        description: 'Find Cool Widget registries on this Geo node',
        feature_flag: :geo_cool_widget_replication # REMOVE THIS LINE
  ```

- [ ] Add a row for Cool Widgets to the `Data types` table in [Geo data types support](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/geo/replication/datatypes.md#data-types)
- [ ] Add a row for Cool Widgets to the `Limitations on replication/verification` table in [Geo data types support](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/geo/replication/datatypes.md#limitations-on-replicationverification). If the row already exists, then update it to show that Replication and Verification is released in the current version.
