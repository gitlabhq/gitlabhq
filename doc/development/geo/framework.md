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

    private

    # Specify the model this replicator belongs to
    def model
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
