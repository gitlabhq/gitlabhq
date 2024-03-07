---
status: accepted
creation-date: "2021-11-18"
authors: [ "@nolith" ]
coach: "@glopezfernandez"
approvers: [ "@marin" ]
owning-stage: "~devops::data stores"
participating-stages: []
---

<!-- vale gitlab.FutureTense = NO -->

# Object storage: `direct_upload` consolidation

## Abstract

GitLab stores three classes of user data: database records, Git
repositories, and user-uploaded files (which are referred to as
file storage throughout the blueprint).

The user and contributor experience for our file
storage has room for significant improvement:

- Initial GitLab setup experience requires creation and setup of 13
  buckets, instead of just 1.
- Features using file storage require contributors to think about both local
  storage and object storage, which leads to friction and
  complexity. This often results in broken features and security issues.
- Contributors who work on file storage often also have to write code
  for Workhorse, Omnibus, and cloud native GitLab (CNG).

## Problem definition

Object storage is a fundamental component of GitLab, providing the
underlying implementation for shared, distributed, highly-available
(HA) file storage.

Over time, we have built support for object storage across the
application, solving specific problems in a
[multitude of iterations](https://handbook.gitlab.com/handbook/company/working-groups/object-storage/#company-efforts-on-uploads).
This has led to increased complexity across the board, from development
(new features and bug fixes) to installation:

- New GitLab installations require the creation and configuration of
  several object storage buckets instead of just one, as each group of
  features requires its own. This has an impact on the installation
  experience and new feature adoption, and takes us further away from
  boring solutions.
- The release of cloud native GitLab required the removal of NFS
  shared storage and the development of direct upload, a feature that
  was expanded, milestone after milestone, to several type of uploads,
  but never enabled globally.
- Today, GitLab supports both local storage and object storage. Local
  storage only works on single box installations or with a NFS, which
  [we no longer recommend](../../../administration/nfs.md) to our
  users and is no longer in use on GitLab.com.
- Understanding all the moving parts and the flow is extremely
  complicated: we have CarrierWave, Fog, Go S3/Azure SDKs, all
  being used, and that complicates testing as well.
- Fog and CarrierWave are not maintained to the level of the native
  SDKs (for example, AWS S3 SDK), so we have to maintain or monkey
  patch those tools to support requested customer features
  (for example, [issue #242245](https://gitlab.com/gitlab-org/gitlab/-/issues/242245))
  that would normally be "free".
- In many cases, we copy around object storage files needlessly
  (for example, [issue #285597](https://gitlab.com/gitlab-org/gitlab/-/issues/285597)).
  Large files (for example, LFS and packages) are slow to finalize or don't work
  at all as a result.

## Improvements over the current situation

The following is a brief description of the main directions we can take to
remove the pain points affecting our object storage implementation.

This is also available as [a YouTube video](https://youtu.be/X9V_w8hsM8E) recorded for the
[Object Storage Working Group](https://about.gitlab.com/company/team/structure/working-groups/object-storage/).

### Simplify GitLab architecture by shipping MinIO

In the beginning, object storage support was a Premium feature, not
part of our CE distribution. Because of that, we had to support both
local storage and object storage.

With local storage, there is the assumption of a shared storage
between components. This can be achieved by having a single box
installation, without HA, or with a NFS, which
[we no longer recommend](../../../administration/nfs.md).

We have a testing gap on object storage. It also requires Workhorse
and MinIO, which are not present in our pipelines, so too much is
replaced by a mock implementation. Furthermore, the presence of a
shared disk, both in CI and in local development, often hides broken
implementations until we deploy on an HA environment.

One consideration we can take is to investigate shipping MinIO as part of the product. This could reduce the differences
between a cloud and a local installation, standardizing our file
storage on a single technology.

The removal of local disk operations would reduce the complexity of
development as well as mitigate several security attack vectors as
we no longer write user-provided data on the local storage.

It would also reduce human errors as we will always run a local object
storage in development mode and any local file disk access should
raise a red flag during the merge request review.

This effort is described in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/6099).

Before considering any specific third-party technology, the
open source software licensing implications should be considered. As of 23 April 2021, [MinIO is subject to the AGPL v3 license](https://github.com/minio/minio/commit/069432566fcfac1f1053677cc925ddafd750730a). GitLab Legal must be consulted before any decision is taken to ship MinIO as proposed in this blueprint.

### Enable direct upload by default on every upload

Because every group of features requires its own bucket, we don't have
direct upload enabled everywhere. Contributing a new upload requires
coding it in both Ruby on Rails and Go.

Implementing a new feature that does not have a dedicated bucket
requires the developer to also create a merge request in Omnibus
and CNG, as well as coordinate with SREs to configure the new bucket
for our own environments.

This also slows down feature adoptions, because our users need to
reconfigure GitLab and prepare a new bucket in their
infrastructure. It also makes the initial installation more complex
feature after feature.

Implementing a direct upload by default, with a
[consolidated object storage configuration](../../../administration/object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)
will reduce the number of merge requests needed to ship a new feature
from four to only one. It will also remove the need for SRE
intervention as the bucket will always be the same.

This will simplify our development and review processes, as well as
the GitLab configuration file. And every user will immediately have
access to new features without infrastructure chores.

### Simplify object storage code

Our implementation is built on top of a 3rd-party framework where
every object storage client is a 3rd-party library. Unfortunately some
of them are unmaintained.
[We have customers who cannot push 5 GB Git LFS objects](https://gitlab.com/gitlab-org/gitlab/-/issues/216442),
but with such a vital feature implemented in 3rd-party libraries we
are slowed down in fixing it, and we also rely on external maintainers
to merge and release fixes.

Before the introduction of direct upload, using the
[CarrierWave](https://github.com/carrierwaveuploader/carrierwave)
library, _"a gem that provides a simple and extremely flexible way to
upload files from Ruby applications."_, was the boring solution.
However this is no longer our use-case, as we upload files from
Workhorse, and we had to [patch CarrierWave's internals](https://gitlab.com/gitlab-org/gitlab/-/issues/285597#note_452696638)
to support direct upload.

A brief proposal covering CarrierWave removal and a new streamlined
internal upload API is described
[in this issue comment](https://gitlab.com/gitlab-org/gitlab/-/issues/213288#note_325358026).

Ideally, we wouldn't need to duplicate object storage clients in Go
and Ruby. By removing CarrierWave, we can make use of the officially
supported native clients when the provider S3 compatibility level is
not sufficient.

## Iterations

In this section we list some possible iterations. This is not
intended to be the final roadmap, but is a conversation started for the
Object Storage Working Group.

1. Create a new catchall bucket and a unified internal API for
   authorization without CarrierWave.
1. Ship MinIO with Omnibus (CNG images already include it).
1. Expand GitLab-QA to cover all the supported configurations.
1. Deprecate local disk access.
1. Deprecate configurations with multiple buckets.
1. Implement a bucket-to-bucket migration.
1. Migrate the current CarrierWave uploads to the new implementation.
1. On the next major release: Remove support for local disk access and
   configurations with multiple buckets.

### Benefits of the current iteration plan

The current plan is designed to provide tangible benefits from the
first step.

With the introduction of the catchall bucket, every upload currently
not subject to direct upload will get its benefits, and new features
could be shipped with a single merge request.

Shipping MinIO with Omnibus will allow us to default new installations
to object storage, and Omnibus could take care of creating
buckets. This will simplify HA installation outside of Kubernetes.

Then we can migrate each CarrierWave uploader to the new
implementation, up to a point where GitLab installation will only
require one bucket.

## Additional reading materials

- [Uploads development guide](../../../development/uploads/index.md).
- [Speed up the monolith, building a smart reverse proxy in Go](https://archive.fosdem.org/2020/schedule/event/speedupmonolith/): a presentation explaining a bit of workhorse history and the challenge we faced in releasing the first cloud-native installation.
- [Object Storage improvements epic](https://gitlab.com/groups/gitlab-org/-/epics/483).
- We are moving to GraphQL API, but [we do not support direct upload](https://gitlab.com/gitlab-org/gitlab/-/issues/280819).
