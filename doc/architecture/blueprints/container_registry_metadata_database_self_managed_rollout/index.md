---
status: proposed
creation-date: "2023-06-09"
authors: [ "@hswimelar" ]
coach: "@grzesiek"
approvers: [ "@trizzi", "@sgoldstein" ]
owning-stage: "~devops::package"
participating-stages: []
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# Container registry self-managed database rollout

## Summary

The latest iteration of the [container registry](https://gitlab.com/gitlab-org/container-registry)
has been rearchitected to use a PostgreSQL database and deployed on GitLab.com.
Now we must bring the advantages provided by the database to self-managed users.
While the container registry retains the capacity to run without the new database,
many new and highly desired features cannot be implemented without it.
Additionally, unifying the registry used for GitLab.com and for self-managed
allows us to provide a cohesive user experience and reduces the burden
associated with maintaining the old registry implementation. To accomplish this,
we plan to eventually require all self-managed to migrate to the new registry
database, so that we may deprecate and remove support for the old object storage
metadata subsystem.

This document seeks to describe how we may use the proven core migration
functionality, which was used to migrate millions of container images on GitLab.com,
to enable self-managed users to enjoy the benefits of the metadata database.

## Motivation

Enabling self-managed users to migrate to the new metadata database allows these
users to take advantage of the new features that require the database. Additionally,
the greater adoption of the database allows the container registry team to focus
our knowledge and capacity, and will eventually allow us to fully remove the old
registry metadata subsystem, greatly improving the maintainability and stability
of the container registry for both GitLab.com and for self-managed users.

### Goals

- Progressively rollout the new dependency of a PostgreSQL database instance for the registry for charts and omnibus deployments.
- Progressively rollout automation for the registry PostgreSQL database instance for charts and omnibus deployments.
- Develop processes and tools that self-managed admins can use to migrate existing registry deployments to the metadata database.
- Develop processes and tools that self-managed admins can use spin up fresh installs of the container registry which use the metadata database.
- Create a plan which will eventually allow us to fully drop support for original object storage metadata subsystem.

### Non-Goals

- Developing new container registry features outside the scope of enabling admins to migrate to the metadata database.
- Determining lifecycle support decisions, such as when to default to the database, and when to end support for non-database registries.

## Proposal

There are two main components that must be further developed in order for
self-managed admins to move to the registry database: the deployment environment and
the registry migration tooling.

For the deployment environments need to document what the user needs to do to set up their
deployment such that the registry has access to a suitable database given the
expected registry workload. As well as develop tooling and automation to ease
the setup and maintenance of the registry database for new and existing deploys.

For the registry, we need to develop and validate import tooling which
coordinates with the core import functionality which was used to migrate all
container images on GitLab.com. Additionally, we should provide estimated import
times for admins for each supported storage driver.

During the beta phase, we can highlight key features of our work to provide a
quick reference for what features we have now, are planning, their statuses, and
an excutive summary of the overall state of the migration experience.
This could be advertised to self-managed users via a simple chart, allowing them
to tell at a glance the status of this project and determine if it is feature-
complete enough for their needs and level of risk tolerance.

This should be documented in the container registry administration documentation,
rather than in this blueprint. Providing this information there will place it in
a familiar place for self-managed admins, will allow for logical cross-linking
from other sections of the same document, such as from the garbage collection
section.

For example:

The metadata database is in early beta for self-managed users. The core migration
process for existing registries has been implemented, and online garbage collection
is fully implemented. Certain database enabled features are only enabled for GitLab.com
and automatic database provisioning for the registry database is not available.
See the table below for the status of features related to the container
registry database.

| Feature                     | Description                                                         | Status             | Link                                                                                           |
| --------------------------- | ------------------------------------------------------------------- | ------------------ | ---------------------------------------------------------------------------------------------- |
| Import Tool                 | Allows existing deployments to migrate to the database.             | Completed          | [Import Tool](https://gitlab.com/gitlab-org/container-registry/-/issues/884)                   |
| Automatic Import Validation | Tests that the import maintained data integrity of imported images. | Backlog            | [Validate self-managed imports](https://gitlab.com/gitlab-org/container-registry/-/issues/938) |
| Foo Bar                     | Lorem ipsum dolor sit amet.                                         | Scheduled for 16.5 | <LINK>                                                                                         |

### Structuring Support by Driver

The import operation heavily relies on the object storage driver implementation
to iterate over all registry metadata so that it can be stored in the database.
It's possible that implementation differences in the driver will make a
meaningful impact on the performance and reliability of the import process.

The following two sections briefly summarize several points for and against
structuring support by driver.

#### Arguments Opposed to Structuring Support by Driver

Each storage driver is well abstracted in the code, specifically the import process
makes use of the following Methods:

- Walk
- List
- GetContent
- Stat
- Reader

Each of the methods is a read method we do not need to create or delete data via
the object storage methods. Additionally, all of these methods are standard API
methods.

Given that we're not mutating data via object storage as part of the import
process, we should not need to double-check these drivers or try to predict
potential errors. Relying on user feedback during the beta to direct any efforts
we should be making here could prevent us from scheduling unnecessary work.

#### Arguments in Favor of Structuring Support by Driver

Our experience with enhancing and supporting offline garbage collection has
shown that while the storage driver implementation should not matter, it does.
The drivers have proven to have important differences in performance and
reliability. Many of the planned possible driver-related improvements are
related to testing and stability, rather than outright new work for each driver.

In particular, retries and error reporting across storage drivers are not as
standardized as one would hope for, and therefore there is a potential that a
long-running import process could be interrupted by an error that could have
been retried.

Creating import estimates based on combinations of the registry size and storage
driver, would also be of use to self-managed admins, looking to schedule their
migration. There will be a difference here between local filesystem storage and
object storage and there could be a difference between the object storage
providers as well.

Also, we could work with the importer to smooth out the differences in the
storage drivers. Even without unified retryable error reporting from the storage
drivers, we could have the importer retry more time and for more errors. There's
a risk we would retry several times on non-retryable errors, but since no writes
are being made to object storage, this should not ultimately be harmful.

Additionally, implementing [Validate self-managed imports](https://gitlab.com/gitlab-org/container-registry/-/issues/938)
would perform a consistency check against a sample of images before and after
import which would lead to greater consistency across all storage driver implementations.

## Design and Implementation Details

### The Import Tool

The [import tool](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/database-import-tool.md)
is a well-validated component of the container registry project that we have used
from the beginning as a way to perform local testing. This tool is a thin wrapper
over the core import functionality — the code which handles the import logic has
been extensively validated.

While the core import functionality is solid, we must ensure that this tool and
the surrounding process will enable non-expert users to import their registries
with both minimal risk and with minimal support from GitLab team members.
Therefore, the most important work remaining is crafting the UX of this tooling
such that those goals are met. This
[epic](https://gitlab.com/groups/gitlab-org/-/epics/8602) captures many of the
proposed improvements.

#### Design

The tool is designed such that a single execution flow can support both users
with large registries with strict uptime requirements who can take advantage of
a more involved process to reduce read-only time to the absolute minimum as well
as users with small registries who benefit from a streamlined workflow. This is
achieved via the same pre import, then full import cycle that was used on
GitLab.com, along with an additional step to catalog all unreferenced blobs held
in common storage.

##### One-Shot Import

In most cases, a user can simply choose to run the import tool while the registry
is offline or read-only in mode. This will be similar to what admins must
already do in order to run offline garbage collection. Each step completes in
sequence, moving directly to the next. The command exits when the import process
is complete and the registry is ready to make full use of the metadata database.

##### Minimal Downtime Import

For users with large registries and who are interested in the minimum possible
downtime, each step can be ran independently when the tool is passed the appropriate
flag. The user will first run the pre-import step while the registry is
performing its usual workload. Once that has completed, and the user is ready
to stop writes to the registry, the tag import step can be ran. As with the GitLab.com
migration, importing tags requires that the registry be offline or in
read-only mode. This step does the minimum possible work to achieve fast and
efficient tag imports and will always be the fastest of the three steps, reducing
the downtime component to a fraction of the total import time. The user can then
bring up the registry configured to use the metadata database. After that, the
user is free to run the third step during standard registry operations. This step
makes any dangling blobs in common storage visible to the database and therefore
the online garbage collection process.

### Distribution Paths

Tooling, process, and documentation will need to be developed in order to
support users who wish to use the metadata database, especially in regards to
providing a foundation for the new database instance required for the migration.

For new deployments, we should wait until we've moved to general support, have
automation in place for the registry database and migration, and have a major
GitLab version bump before enabling the database by default for self-managed.

#### Omnibus

#### Charts

## Alternative Solutions

### Do Nothing

#### Pros

- The database and associated features are generally most useful for large-scale, high-availability deployments.
- Eliminate the need to support an additional logical or physical database for self-managed deployments.

#### Cons

- The registry on GitLab.com and the registry used by self-managed will greatly diverge in supported features over time.
- The maintenance burden of supporting two registry implementations will reduce the velocity at which new registry features can be released.
- The registry on GitLab.com stops being an effective way to validate changes before they are released to self-managed.
- Large self-managed users continue to not be able to scale the registry to suit their needs.

### Gradual Migration

This approach would be to exactly replicate the GitLab.com migration on
self-managed.

#### Pros

- Replicate an already successful process.
- Scope downtime by repository, rather than instance.

#### Cons

- Dramatically increased complexity in all aspects of the migration process.
- Greatly increased possibility of data consistency issues.
- Less clear demarcation of registry migration progress.
