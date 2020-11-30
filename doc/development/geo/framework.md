---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Geo self-service framework

NOTE: **Note:**
This document is subject to change as we continue to implement and iterate on the framework.
Follow the progress in the [epic](https://gitlab.com/groups/gitlab-org/-/epics/2161).
If you need to replicate a new data type, reach out to the Geo
team to discuss the options. You can contact them in `#g_geo` on Slack
or mention `@geo-team` in the issue or merge request.

Geo provides an API to make it possible to easily replicate data types
across Geo nodes. This API is presented as a Ruby Domain-Specific
Language (DSL) and aims to make it possible to replicate data with
minimal effort of the engineer who created a data type.

## Nomenclature

Before digging into the API, developers need to know some Geo-specific
naming conventions:

- **Model**:
  A model is an Active Model, which is how it is known in the entire
  Rails codebase. It usually is tied to a database table. From Geo
  perspective, a model can have one or more resources.

- **Resource**:
  A resource is a piece of data that belongs to a model and is
  produced by a GitLab feature. It is persisted using a storage
  mechanism. By default, a resource is not a Geo replicable.

- **Data type**:
  Data type is how a resource is stored. Each resource should
  fit in one of the data types Geo supports:
  - Git repository
  - Blob
  - Database

  For more detail, see [Data types](../../administration/geo/replication/datatypes.md).

- **Geo Replicable**:
  A Replicable is a resource Geo wants to sync across Geo nodes. There
  is a limited set of supported data types of replicables. The effort
  required to implement replication of a resource that belongs to one
  of the known data types is minimal.

- **Geo Replicator**:
  A Geo Replicator is the object that knows how to replicate a
  replicable. It's responsible for:
  - Firing events (producer)
  - Consuming events (consumer)

  It's tied to the Geo Replicable data type. All replicators have a
  common interface that can be used to process (that is, produce and
  consume) events. It takes care of the communication between the
  primary node (where events are produced) and the secondary node
  (where events are consumed). The engineer who wants to incorporate
  Geo in their feature will use the API of replicators to make this
  happen.

- **Geo Domain-Specific Language**:
  The syntactic sugar that allows engineers to easily specify which
  resources should be replicated and how.

## Geo Domain-Specific Language

### The replicator

First of all, you need to write a replicator. The replicators live in
[`ee/app/replicators/geo`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/app/replicators/geo).
For each resource that needs to be replicated, there should be a
separate replicator specified, even if multiple resources are tied to
the same model.

For example, the following replicator replicates a package file:

```ruby
module Geo
  class PackageFileReplicator < Gitlab::Geo::Replicator
    # Include one of the strategies your resource needs
    include ::Geo::BlobReplicatorStrategy

    # Specify the CarrierWave uploader needed by the used strategy
    def carrierwave_uploader
      model_record.file
    end

    # Specify the model this replicator belongs to
    def self.model
      ::Packages::PackageFile
    end

    # The feature flag follows the format `geo_#{replicable_name}_replication`,
    # so here it would be `geo_package_file_replication`
    def self.replication_enabled_by_default?
      false
    end
  end
end
```

The class name should be unique. It also is tightly coupled to the
table name for the registry, so for this example the registry table
will be `package_file_registry`.

For the different data types Geo supports there are different
strategies to include. Pick one that fits your needs.

### Linking to a model

To tie this replicator to the model, you need to add the following to
the model code:

```ruby
class Packages::PackageFile < ApplicationRecord
  include ::Gitlab::Geo::ReplicableModel

  with_replicator Geo::PackageFileReplicator
end
```

### API

When this is set in place, it's easy to access the replicator through
the model:

```ruby
package_file = Packages::PackageFile.find(4) # just a random ID as example
replicator = package_file.replicator
```

Or get the model back from the replicator:

```ruby
replicator.model_record
=> <Packages::PackageFile id:4>
```

The replicator can be used to generate events, for example in
`ActiveRecord` hooks:

```ruby
  after_create_commit -> { replicator.publish_created_event }
```

#### Library

The framework behind all this is located in
[`ee/lib/gitlab/geo/`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/lib/gitlab/geo).

## Existing Replicator Strategies

Before writing a new kind of Replicator Strategy, check below to see if your
resource can already be handled by one of the existing strategies. Consult with
the Geo team if you are unsure.

### Blob Replicator Strategy

Models that use
[CarrierWave's](https://github.com/carrierwaveuploader/carrierwave) `Uploader::Base`
can be easily supported by Geo with the `Geo::BlobReplicatorStrategy` module.

First, each file should have its own primary ID and model. Geo strongly
recommends treating *every single file* as a first-class citizen, because in
our experience this greatly simplifies tracking replication and verification
state.

For example, to add support for files referenced by a `Widget` model with a
`widgets` table, you would perform the following steps:

#### Replication

1. Include `Gitlab::Geo::ReplicableModel` in the `Widget` class, and specify
   the Replicator class `with_replicator Geo::WidgetReplicator`.

   At this point the `Widget` class should look like this:

   ```ruby
   # frozen_string_literal: true

   class Widget < ApplicationRecord
     include ::Gitlab::Geo::ReplicableModel

     with_replicator Geo::WidgetReplicator

     mount_uploader :file, WidgetUploader

     def local?
       # Must to be implemented, Check the uploader's storage types
       file_store == ObjectStorage::Store::LOCAL
     end

     # @param primary_key_in [Range, Widget] arg to pass to primary_key_in scope
     # @return [ActiveRecord::Relation<Widget>] everything that should be synced to this node, restricted by primary key
     def self.replicables_for_current_secondary(primary_key_in)
       # Should be implemented. The idea of the method is to restrict
       # the set of synced items depending on synchronization settings
     end
     ...
   end
   ```

   If there is a common constraint for records to be available for replication,
   make sure to also overwrite the `available_replicables` scope.

1. Create `ee/app/replicators/geo/widget_replicator.rb`. Implement the
   `#carrierwave_uploader` method which should return a `CarrierWave::Uploader`,
   and implement the class method `.model` to return the `Widget` class:

   ```ruby
   # frozen_string_literal: true

   module Geo
     class WidgetReplicator < Gitlab::Geo::Replicator
       include ::Geo::BlobReplicatorStrategy

       def self.model
         ::Widget
       end

       def carrierwave_uploader
         model_record.file
       end

       # The feature flag follows the format `geo_#{replicable_name}_replication`,
       # so here it would be `geo_widget_replication`
       def self.replication_enabled_by_default?
         false
       end
     end
   end
   ```

1. Add this replicator class to the method `replicator_classes` in
   `ee/lib/gitlab/geo.rb`:

   ```ruby
   REPLICATOR_CLASSES = [
      ::Geo::PackageFileReplicator,
      ::Geo::WidgetReplicator
   ]
   end
   ```

1. Create `ee/spec/replicators/geo/widget_replicator_spec.rb` and perform
   the necessary setup to define the `model_record` variable for the shared
   examples:

   ```ruby
   # frozen_string_literal: true

   require 'spec_helper'

   RSpec.describe Geo::WidgetReplicator do
     let(:model_record) { build(:widget) }

     it_behaves_like 'a blob replicator'
   end
   ```

1. Create the `widget_registry` table, with columns ordered according to [our guidelines](../ordering_table_columns.md) so Geo secondaries can track the sync and
   verification state of each Widget's file. This migration belongs in `ee/db/geo/migrate`:

   ```ruby
   # frozen_string_literal: true

   class CreateWidgetRegistry < ActiveRecord::Migration[6.0]
     include Gitlab::Database::MigrationHelpers

     DOWNTIME = false

     disable_ddl_transaction!

     def up
       unless table_exists?(:widget_registry)
         ActiveRecord::Base.transaction do
           create_table :widget_registry, id: :bigserial, force: :cascade do |t|
             t.integer :widget_id, null: false
             t.integer :state, default: 0, null: false, limit: 2
             t.integer :retry_count, default: 0, limit: 2
             t.datetime_with_timezone :retry_at
             t.datetime_with_timezone :last_synced_at
             t.datetime_with_timezone :created_at, null: false
             t.text :last_sync_failure

             t.index :widget_id, name: :index_widget_registry_on_widget_id
             t.index :retry_at
             t.index :state
           end
         end
       end

       add_text_limit :widget_registry, :last_sync_failure, 255
     end

     def down
       drop_table :widget_registry
     end
   end
   ```

1. Create `ee/app/models/geo/widget_registry.rb`:

   ```ruby
   # frozen_string_literal: true

   class Geo::WidgetRegistry < Geo::BaseRegistry
     include Geo::ReplicableRegistry

     MODEL_CLASS = ::Widget
     MODEL_FOREIGN_KEY = :widget_id

     belongs_to :widget, class_name: 'Widget'
   end
   ```

1. Update `REGISTRY_CLASSES` in `ee/app/workers/geo/secondary/registry_consistency_worker.rb`.
1. Add `widget_registry` to `ActiveSupport::Inflector.inflections` in `config/initializers_before_autoloader/000_inflections.rb`.
1. Create `ee/spec/factories/geo/widget_registry.rb`:

   ```ruby
   # frozen_string_literal: true

   FactoryBot.define do
     factory :geo_widget_registry, class: 'Geo::WidgetRegistry' do
       widget
       state { Geo::WidgetRegistry.state_value(:pending) }

       trait :synced do
         state { Geo::WidgetRegistry.state_value(:synced) }
         last_synced_at { 5.days.ago }
       end

       trait :failed do
         state { Geo::WidgetRegistry.state_value(:failed) }
         last_synced_at { 1.day.ago }
         retry_count { 2 }
         last_sync_failure { 'Random error' }
       end

       trait :started do
         state { Geo::WidgetRegistry.state_value(:started) }
         last_synced_at { 1.day.ago }
         retry_count { 0 }
       end
     end
   end
   ```

1. Create `ee/spec/models/geo/widget_registry_spec.rb`:

   ```ruby
   # frozen_string_literal: true

   require 'spec_helper'

   RSpec.describe Geo::WidgetRegistry, :geo, type: :model do
     let_it_be(:registry) { create(:geo_widget_registry) }

     specify 'factory is valid' do
       expect(registry).to be_valid
     end

     include_examples 'a Geo framework registry'

     describe '.find_registry_differences' do
       ... # To be implemented
     end
   end
   ```

Widgets should now be replicated by Geo.

#### Verification

There are two ways to add verification related fields so that the Geo primary
can track verification state.

##### Option 1: Add verification state fields to the existing `widgets` table itself

1. Add a migration to add columns ordered according to [our guidelines](../ordering_table_columns.md)
   for verification state to the widgets table:

   ```ruby
   # frozen_string_literal: true

   class AddVerificationStateToWidgets < ActiveRecord::Migration[6.0]
     DOWNTIME = false

     def change
       change_table(:widgets) do |t|
         t.integer :verification_state, default: 0, limit: 2, null: false
         t.column :verification_started_at, :datetime_with_timezone
         t.integer :verification_retry_count, limit: 2
         t.column :verification_retry_at, :datetime_with_timezone
         t.column :verified_at, :datetime_with_timezone
         t.binary :verification_checksum, using: 'verification_checksum::bytea'

         # rubocop:disable Migration/AddLimitToTextColumns
         t.text :verification_failure
         # rubocop:enable Migration/AddLimitToTextColumns
       end
     end
   end
   ```

1. Adding a `text` column also [requires](../database/strings_and_the_text_data_type.md#add-a-text-column-to-an-existing-table)
   setting a limit:

   ```ruby
   # frozen_string_literal: true

   class AddVerificationFailureLimitToWidgets < ActiveRecord::Migration[6.0]
     include Gitlab::Database::MigrationHelpers

     DOWNTIME = false

     disable_ddl_transaction!

     CONSTRAINT_NAME = 'widget_verification_failure_text_limit'

     def up
       add_text_limit :widget, :verification_failure, 255, constraint_name: CONSTRAINT_NAME
     end

     def down
       remove_check_constraint(:widget, CONSTRAINT_NAME)
     end
   end
   ```

1. Add an index on `verification_state` to ensure verification can be performed efficiently:

   ```ruby
   # frozen_string_literal: true

   class AddVerificationStateIndexToWidgets < ActiveRecord::Migration[6.0]
     include Gitlab::Database::MigrationHelpers

     DOWNTIME = false

     disable_ddl_transaction!

     def up
       add_concurrent_index :widgets, :verification_state, name: "index_widgets_on_verification_state"
     end

     def down
       remove_concurrent_index :widgets, :verification_state
     end
   end
   ```

1. Add the `Gitlab::Geo::VerificationState` concern to the `widget` model if it is not already included in `Gitlab::Geo::ReplicableModel`:

   ```ruby
   class Widget < ApplicationRecord
     ...
     include ::Gitlab::Geo::VerificationState
     ...
   end
   ```

##### Option 2: Create a separate `widget_states` table with verification state fields

1. Create a `widget_states` table and add an index on `verification_state` to ensure verification can be performed efficiently. Order the columns according to [the guidelines](../ordering_table_columns.md):

   ```ruby
   # frozen_string_literal: true

   class CreateWidgetStates < ActiveRecord::Migration[6.0]
     include Gitlab::Database::MigrationHelpers

     DOWNTIME = false

     disable_ddl_transaction!

     def up
       unless table_exists?(:widget_states)
         with_lock_retries do
           create_table :widget_states, id: false do |t|
             t.references :widget, primary_key: true, null: false, foreign_key: { on_delete: :cascade }
             t.integer :verification_state, default: 0, limit: 2, null: false
             t.column :verification_started_at, :datetime_with_timezone
             t.datetime_with_timezone :verification_retry_at
             t.datetime_with_timezone :verified_at
             t.integer :verification_retry_count, limit: 2
             t.binary :verification_checksum, using: 'verification_checksum::bytea'
             t.text :verification_failure

             t.index :verification_state, name: "index_widget_states_on_verification_state"
           end
         end
       end

       add_text_limit :widget_states, :verification_failure, 255
     end

     def down
       drop_table :widget_states
     end
   end
   ```

1. Add the following lines to the `widget_state.rb` model:

   ```ruby
   class WidgetState < ApplicationRecord
     ...
     self.primary_key = :widget_id

     include ::Gitlab::Geo::VerificationState

     belongs_to :widget, inverse_of: :widget_state
     ...
   end
   ```

1. Add the following lines to the `widget` model:

   ```ruby
   class Widget < ApplicationRecord
     ...
     has_one :widget_state, inverse_of: :widget

     delegate :verification_retry_at, :verification_retry_at=,
              :verified_at, :verified_at=,
              :verification_checksum, :verification_checksum=,
              :verification_failure, :verification_failure=,
              :verification_retry_count, :verification_retry_count=,
              to: :widget_state
     ...
   end
   ```

To do: Add verification on secondaries. This should be done as part of
[Geo: Self Service Framework - First Implementation for Package File verification](https://gitlab.com/groups/gitlab-org/-/epics/1817)

Widgets should now be verified by Geo.

#### Metrics

Metrics are gathered by `Geo::MetricsUpdateWorker`, persisted in
`GeoNodeStatus` for display in the UI, and sent to Prometheus:

1. Add fields `widgets_count`, `widgets_checksummed_count`,
   `widgets_checksum_failed_count`, `widgets_synced_count`,
   `widgets_failed_count`, and `widgets_registry_count` to
   `GET /geo_nodes/status` example response in
   `doc/api/geo_nodes.md`.
1. Add the same fields to `GET /geo_nodes/status` example response in
   `ee/spec/fixtures/api/schemas/public_api/v4/geo_node_status.json`.
1. Add fields `geo_widgets`, `geo_widgets_checksummed`,
   `geo_widgets_checksum_failed`, `geo_widgets_synced`,
   `geo_widgets_failed`, and `geo_widgets_registry` to
   `Sidekiq metrics` table in
   `doc/administration/monitoring/prometheus/gitlab_metrics.md`.
1. Add the following to the parameterized table in
   `ee/spec/models/geo_node_status_spec.rb`:

   ```ruby
   Geo::WidgetReplicator | :widget | :geo_widget_registry
   ```

1. Add the following to `spec/factories/widgets.rb`:

   ```ruby
   trait(:verification_succeeded) do
     with_file
     verification_checksum { 'abc' }
     verification_state { Widget.verification_state_value(:verification_succeeded) }
   end

   trait(:verification_failed) do
     with_file
     verification_failure { 'Could not calculate the checksum' }
     verification_state { Widget.verification_state_value(:verification_failed) }
   end
   ```

1. Make sure the factory also allows setting a `project` attribute. If the model
   does not have a direct relation to a project, you can use a `transient`
   attribute. Check out `spec/factories/merge_request_diffs.rb` for an example.

Widget replication and verification metrics should now be available in the API,
the Admin Area UI, and Prometheus.

#### GraphQL API

1. Add a new field to `GeoNodeType` in
   `ee/app/graphql/types/geo/geo_node_type.rb`:

   ```ruby
   field :widget_registries, ::Types::Geo::WidgetRegistryType.connection_type,
         null: true,
         resolver: ::Resolvers::Geo::WidgetRegistriesResolver,
         description: 'Find widget registries on this Geo node',
         feature_flag: :geo_widget_replication
   ```

1. Add the new `widget_registries` field name to the `expected_fields` array in
   `ee/spec/graphql/types/geo/geo_node_type_spec.rb`.
1. Create `ee/app/graphql/resolvers/geo/widget_registries_resolver.rb`:

   ```ruby
   # frozen_string_literal: true

   module Resolvers
     module Geo
       class WidgetRegistriesResolver < BaseResolver
         include RegistriesResolver
       end
     end
   end
   ```

1. Create `ee/spec/graphql/resolvers/geo/widget_registries_resolver_spec.rb`:

   ```ruby
   # frozen_string_literal: true

   require 'spec_helper'

   RSpec.describe Resolvers::Geo::WidgetRegistriesResolver do
     it_behaves_like 'a Geo registries resolver', :geo_widget_registry
   end
   ```

1. Create `ee/app/finders/geo/widget_registry_finder.rb`:

   ```ruby
   # frozen_string_literal: true

   module Geo
     class WidgetRegistryFinder
       include FrameworkRegistryFinder
     end
   end
   ```

1. Create `ee/spec/finders/geo/widget_registry_finder_spec.rb`:

   ```ruby
   # frozen_string_literal: true

   require 'spec_helper'

   RSpec.describe Geo::WidgetRegistryFinder do
     it_behaves_like 'a framework registry finder', :geo_widget_registry
   end
   ```

1. Create `ee/app/graphql/types/geo/widget_registry_type.rb`:

   ```ruby
   # frozen_string_literal: true

   module Types
     module Geo
       # rubocop:disable Graphql/AuthorizeTypes because it is included
       class WidgetRegistryType < BaseObject
         include ::Types::Geo::RegistryType

         graphql_name 'WidgetRegistry'
         description 'Represents the Geo sync and verification state of a widget'

         field :widget_id, GraphQL::ID_TYPE, null: false, description: 'ID of the Widget'
       end
     end
   end
   ```

1. Create `ee/spec/graphql/types/geo/widget_registry_type_spec.rb`:

   ```ruby
   # frozen_string_literal: true

   require 'spec_helper'

   RSpec.describe GitlabSchema.types['WidgetRegistry'] do
     it_behaves_like 'a Geo registry type'

     it 'has the expected fields (other than those included in RegistryType)' do
       expected_fields = %i[widget_id]

       expect(described_class).to have_graphql_fields(*expected_fields).at_least
     end
   end
   ```

1. Add integration tests for providing Widget registry data to the frontend via
   the GraphQL API, by duplicating and modifying the following shared examples
   in `ee/spec/requests/api/graphql/geo/registries_spec.rb`:

   ```ruby
   it_behaves_like 'gets registries for', {
     field_name: 'widgetRegistries',
     registry_class_name: 'WidgetRegistry',
     registry_factory: :geo_widget_registry,
     registry_foreign_key_field_name: 'widgetId'
   }
   ```

1. Update the GraphQL reference documentation:

   ```shell
   bundle exec rake gitlab:graphql:compile_docs
   ```

Individual widget synchronization and verification data should now be available
via the GraphQL API.

Make sure to replicate the "update" events. Geo Framework does not currently support
replicating "update" events because all entities added to the framework, by this time,
are immutable. If this is the case
for the entity you're going to add, follow <https://gitlab.com/gitlab-org/gitlab/-/issues/118743>
and <https://gitlab.com/gitlab-org/gitlab/-/issues/118745> as examples to add the new event type.
Also, remove this notice when you've added it.

#### Admin UI

To do: This should be done as part of
[Geo: Implement frontend for Self-Service Framework replicables](https://gitlab.com/groups/gitlab-org/-/epics/2525)

Widget sync and verification data (aggregate and individual) should now be
available in the Admin UI.

#### Releasing the feature

1. In `ee/app/replicators/geo/widget_replicator.rb`, delete the `self.replication_enabled_by_default?` method:

   ```ruby
   module Geo
     class WidgetReplicator < Gitlab::Geo::Replicator
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

1. In `ee/app/graphql/types/geo/geo_node_type.rb`, remove the `feature_flag` option for the released type:

   ```ruby
   field :widget_registries, ::Types::Geo::WidgetRegistryType.connection_type,
         null: true,
         resolver: ::Resolvers::Geo::WidgetRegistriesResolver,
         description: 'Find widget registries on this Geo node',
         feature_flag: :geo_widget_replication # REMOVE THIS LINE
   ```
