---
stage: Systems
group: Geo
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Geo self-service framework
---

NOTE:
This document is subject to change as we continue to implement and iterate on the framework.
Follow the progress in the [epic](https://gitlab.com/groups/gitlab-org/-/epics/2161).
If you need to replicate a new data type, reach out to the Geo
team to discuss the options. You can contact them in `#g_geo` on Slack
or mention `@geo-team` in the issue or merge request.

Geo provides an API to make it possible to easily replicate data types
across Geo sites. This API is presented as a Ruby Domain-Specific
Language (DSL) and aims to make it possible to replicate data with
minimal effort of the engineer who created a data type.

## Geo is a requirement in the definition of done

Geo is the GitLab solution for [disaster recovery](https://about.gitlab.com/direction/geo/disaster_recovery/). A robust disaster recovery solution must replicate **all GitLab data** such that all GitLab services can be successfully restored in their entirety with minimal data loss in the event of a disaster.

For this reason, Geo replication and verification support for GitLab generated data is part of the [definition of done](../contributing/merge_request_workflow.md#definition-of-done). This ensures that new features ship with Geo support and our customers are not exposed to data loss.

Adding Geo support with the Self Service Framework (SSF) is easy and outlined in detail on this page for various types of data. However, for a more general guide that can help you decide if and how you need to add Geo support for a new GitLab feature, [you may start here](../geo.md#ensuring-a-new-feature-has-geo-support).

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
  A Replicable is a resource Geo wants to sync across Geo sites. There
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
  primary site (where events are produced) and the secondary site
  (where events are consumed). The engineer who wants to incorporate
  Geo in their feature uses the API of replicators to make this
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
  end
end
```

The class name should be unique. It also is tightly coupled to the
table name for the registry, so for this example the registry table
is `package_file_registry`.

For the different data types Geo supports there are different
strategies to include. Pick one that fits your needs.

### Linking to a model

To tie this replicator to the model, you need to add the following to
the model code:

```ruby
class Packages::PackageFile < ApplicationRecord
  include ::Geo::ReplicableModel

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

Models that use [CarrierWave's](https://github.com/carrierwaveuploader/carrierwave) `Uploader::Base` are supported by Geo with the `Geo::BlobReplicatorStrategy` module. For example, see how [Geo replication was implemented for Pipeline Artifacts](https://gitlab.com/gitlab-org/gitlab/-/issues/238464).

Each file is expected to have its own primary ID and model. Geo strongly recommends treating *every single file* as a first-class citizen, because in our experience this greatly simplifies tracking replication and verification state.

To implement Geo replication of a new blob-type Model, [open an issue with the provided issue template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Geo%20Replicate%20a%20new%20blob%20type).

To view the implementation steps without opening an issue, [view the issue template file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Geo%20Replicate%20a%20new%20blob%20type.md).

### Repository Replicator Strategy

Models that refer to any Git repository on disk are supported by Geo with the `Geo::RepositoryReplicatorStrategy` module. For example, see how [Geo replication was implemented for Group-level Wikis](https://gitlab.com/gitlab-org/gitlab/-/issues/208147). Note that this issue does not implement verification, since verification of Git repositories was not yet added to the Geo self-service framework. An example implementing verification can be found in the merge request to [Add Snippet repository verification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56596).

Each Git repository is expected to have its own primary ID and model.

To implement Geo replication of a new Git repository-type Model, [open an issue with the provided issue template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Geo%20Replicate%20a%20new%20Git%20repository%20type).

To view the implementation steps without opening an issue, [view the issue template file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Geo%20Replicate%20a%20new%20Git%20repository%20type.md).
