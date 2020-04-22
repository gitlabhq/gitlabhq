# Geo self-service framework (alpha)

NOTE: **Note:** This document might be subjected to change. It's a
proposal we're working on and once the implementation is complete this
documentation will be updated. Follow progress in the
[epic](https://gitlab.com/groups/gitlab-org/-/epics/2161).

NOTE: **Note:** The Geo self-service framework is currently in
alpha. If you need to replicate a new data type, reach out to the Geo
team to discuss the options. You can contact them in `#g_geo` on Slack
or mention `@geo-team` in the issue or merge request.

Geo provides an API to make it possible to easily replicate data types
across Geo nodes. This API is presented as a Ruby Domain-Specific
Language (DSL) and aims to make it possible to replicate data with
minimal effort of the engineer who created a data type.

## Nomenclature

Before digging into the API, developers need to know some Geo-specific
naming conventions.

Model
: A model is an Active Model, which is how it is known in the entire
  Rails codebase. It usually is tied to a database table. From Geo
  perspective, a model can have one or more resources.

Resource
: A resource is a piece of data that belongs to a model and is
  produced by a GitLab feature. It is persisted using a storage
  mechanism. By default, a resource is not a replicable.

Data type
: Data type is how a resource is stored. Each resource should
  fit in one of the data types Geo supports:
:- Git repository
:- Blob
:- Database
: For more detail, see [Data types](../../administration/geo/replication/datatypes.md).

Geo Replicable
: A Replicable is a resource Geo wants to sync across Geo nodes. There
  is a limited set of supported data types of replicables. The effort
  required to implement replication of a resource that belongs to one
  of the known data types is minimal.

Geo Replicator
: A Geo Replicator is the object that knows how to replicate a
  replicable. It's responsible for:
:- Firing events (producer)
:- Consuming events (consumer)
: It's tied to the Geo Replicable data type. All replicators have a
  common interface that can be used to process (that is, produce and
  consume) events. It takes care of the communication between the
  primary node (where events are produced) and the secondary node
  (where events are consumed). The engineer who wants to incorporate
  Geo in their feature will use the API of replicators to make this
  happen.

Geo Domain-Specific Language
: The syntactic sugar that allows engineers to easily specify which
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
package_file = Packages::PackageFile.find(4) # just a random id as example
replicator = package_file.replicator
```

Or get the model back from the replicator:

```ruby
replicator.model_record
=> <Packages::PackageFile id:4>
```

The replicator can be used to generate events, for example in
ActiveRecord hooks:

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

1. Add verification state fields to the `widgets` table so the Geo primary can
   track verification state:

   ```ruby
   # frozen_string_literal: true

   class AddVerificationStateToWidgets < ActiveRecord::Migration[6.0]
     DOWNTIME = false

     def change
       add_column :widgets, :verification_retry_at,  :datetime_with_timezone
       add_column :widgets, :verified_at,  :datetime_with_timezone
       add_column :widgets, :verification_checksum, :string
       add_column :widgets, :verification_failure, :string
       add_column :widgets, :verification_retry_count, :integer
     end
   end
   ```

1. Add a partial index on `verification_failure` and `verification_checksum` to ensure
   re-verification can be performed efficiently:

   ```ruby
   # frozen_string_literal: true

   class AddVerificationFailureIndexToWidgets < ActiveRecord::Migration[6.0]
     include Gitlab::Database::MigrationHelpers

     DOWNTIME = false

     disable_ddl_transaction!

     def up
       add_concurrent_index :widgets, :verification_failure, where: "(verification_failure IS NOT NULL)", name: "widgets_verification_failure_partial"
       add_concurrent_index :widgets, :verification_checksum, where: "(verification_checksum IS NOT NULL)", name: "widgets_verification_checksum_partial"
     end

     def down
       remove_concurrent_index :widgets, :verification_failure
       remove_concurrent_index :widgets, :verification_checksum
     end
   end
   ```

1. Include `Gitlab::Geo::ReplicableModel` in the `Widget` class, and specify
   the Replicator class `with_replicator Geo::WidgetReplicator`.

   At this point the `Widget` class should look like this:

   ```ruby
   # frozen_string_literal: true

   class Widget < ApplicationRecord
     include ::Gitlab::Geo::ReplicableModel

     with_replicator Geo::WidgetReplicator

     mount_uploader :file, WidgetUploader

     ...
   end
   ```

1. Create `ee/app/replicators/geo/widget_replicator.rb`. Implement the
   `#carrierwave_uploader` method which should return a `CarrierWave::Uploader`.
   And implement the private `#model` method to return the `Widget` class.

   ```ruby
   # frozen_string_literal: true

   module Geo
     class WidgetReplicator < Gitlab::Geo::Replicator
       include ::Geo::BlobReplicatorStrategy

       def carrierwave_uploader
         model_record.file
       end

       private

       def model
         ::Widget
       end
     end
   end
   ```

1. Create `ee/spec/replicators/geo/widget_replicator_spec.rb` and perform
   the setup necessary to define the `model_record` variable for the shared
   examples.

   ```ruby
   # frozen_string_literal: true

   require 'spec_helper'

   describe Geo::WidgetReplicator do
     let(:model_record) { build(:widget) }

     it_behaves_like 'a blob replicator'
   end
   ```

1. Create the `widget_registry` table so Geo secondaries can track the sync and
   verification state of each Widget's file:

   ```ruby
   # frozen_string_literal: true

   class CreateWidgetRegistry < ActiveRecord::Migration[5.2]
     DOWNTIME = false

     def change
       create_table :widget_registry, id: :serial, force: :cascade do |t|
         t.integer :widget_id, null: false
         t.integer :state, default: 0, null: false
         t.integer :retry_count, default: 0
         t.string :last_sync_failure, limit: 255
         t.datetime_with_timezone :retry_at
         t.datetime_with_timezone :last_synced_at
         t.datetime_with_timezone :created_at, null: false

         t.index :widget_id, name:  :index_widget_registry_on_repository_id, using: :btree
         t.index :retry_at, name: :index_widget_registry_on_retry_at,  using: :btree
         t.index :state, name: :index_widget_registry_on_state, using:  :btree
       end
     end
   end
   ```

1. Create `ee/app/models/geo/widget_registry.rb`:

   ```ruby
   # frozen_string_literal: true

   class Geo::WidgetRegistry < Geo::BaseRegistry
     include Geo::StateMachineRegistry

     belongs_to :widget, class_name: 'Widget'
   end
   ```

1. Create `ee/spec/factories/geo/widget_registry.rb`:

   ```ruby
   # frozen_string_literal: true

   FactoryBot.define do
     factory :widget_registry, class: 'Geo::WidgetRegistry' do
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

1. Create `ee/spec/models/geo/widget_registry.rb`:

   ```ruby
   # frozen_string_literal: true

   require 'spec_helper'

   describe Geo::WidgetRegistry, :geo, type: :model do
     let_it_be(:registry) { create(:widget_registry) }

     specify 'factory is valid' do
       expect(registry).to be_valid
     end
   end
   ```

Widget files should now be replicated and verified by Geo!

### Verification statistics with Blob Replicator Strategy

GitLab Geo stores statistic data in the `geo_node_statuses` table.

1. Add fields `widget_count`, `widget_checksummed_count`, and `widget_checksum_failed_count`
   to `GeoNodeStatus#RESOURCE_STATUS_FIELDS` array in `ee/app/models/geo_node_status.rb`.
1. Add the same fields to `GeoNodeStatus#PROMETHEUS_METRICS` hash in
   `ee/app/models/geo_node_status.rb`.
1. Add the same fields to `Sidekiq metrics` table in
   `doc/administration/monitoring/prometheus/gitlab_metrics.md`.
1. Add the same fields to `GET /geo_nodes/status` example response in `doc/api/geo_nodes.md`.
1. Modify `GeoNodeStatus#load_verification_data` to make sure the fields mantioned above
   are set:

   ```ruby
     self.widget_count = Geo::WidgetReplicator.model.count
     self.widget_checksummed_count = Geo::WidgetReplicator.checksummed.count
     self.widget_checksum_failed_count = Geo::WidgetReplicator.checksum_failed.count
   ```

1. Make sure `Widget` model has `checksummed` and `checksum_failed` scopes.
1. Update `ee/spec/fixtures/api/schemas/public_api/v4/geo_node_status.json` with new fields.
1. Update `GeoNodeStatus#PROMETHEUS_METRICS` hash in `ee/app/models/geo_node_status.rb` with new fields.
1. Update `Sidekiq metrics` table in `doc/administration/monitoring/prometheus/gitlab_metrics.md` with new fields.
1. Update `GET /geo_nodes/status` example response in `doc/api/geo_nodes.md` with new fields.
1. Update `ee/spec/models/geo_node_status_spec.rb` and `ee/spec/factories/geo_node_statuses.rb` with new fields.
