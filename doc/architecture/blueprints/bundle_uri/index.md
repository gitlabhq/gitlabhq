---
status: proposed
creation-date: "2023-08-04"
authors: [ "@toon" ]
coach: ""
approvers: [ "@mjwood", "@jcaigitlab" ]
owning-stage: "~devops::systems"
participating-stages: []
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# Utilize bundle-uri to reduce Gitaly CPU load

## Summary

[bundle-URI](https://git-scm.com/docs/bundle-uri) is a fairly new concept
in Git that allows the client to download one or more bundles in order to
bootstrap the object database in advance of fetching the remaining objects from
a remote. By having the client download static files from a simple HTTP(S)
server in advance, the work that needs to be done on the remote side is reduced.

Git bundles are files that store a packfile along with some extra metadata,
including a set of refs and a (possibly empty) set of necessary commits. When a
user clones a repository, the server can advertise one or more URIs that serve
these bundles. The client can download these to populate the Git object
database. After it has done this, the negotiation process between server and
client start to see which objects need be fetched. When the client pre-populated
the database with some data from the bundles, the negotiation and transfer of
objects from the server is reduced, putting less load on the server's CPU.

## Motivation

When a user pushes changes, it usually kicks off a CI pipeline with
a bunch of jobs. When the CI runners all clone the repository from scratch,
if they use [`git clone`](/ee/ci/pipelines/settings.md#choose-the-default-git-strategy),
they all start negotiating with the server what they need to clone. This is
really CPU intensive for the server.

Some time ago we've introduced the
[pack-objects](/ee/administration/gitaly/configure_gitaly.md#pack-objects-cache),
but it has some pitfalls. When the tip of a branch changes, a new packfile needs
to be calculated, and the cache needs to be refreshed.

Git bundles are more flexible. It's not a big issue if the bundle doesn't have
all the most recent objects. When it contains a fairly recent state, but is
missing the latest refs, the client (that is, the CI runner) will do a "catch up" and
fetch additional objects after applying the bundle. The set of objects it has to
fetch from will Gitaly be a lot smaller.

### Goals

Reduce the work that needs to be done on the Gitaly servers when a client clones
a repository. This is particularly useful for CI build farms, which generate a
lot of traffic on each commit that's pushed to the server.

With the use bundles, the server has to craft a smaller delta packfiles
compared to the pack files that contain all the objects when no bundles are
used. This reduces the load on the CPU of the server. This has a benefit on the
packfile cache as well, because now the packfiles are smaller and faster to
generate, reducing the chances on cache misses.

### Non-Goals

Using bundle-URIs will **not** reduce the size of repositories stored on disk.
This feature will not be used to offload repositories, neither fully nor
partially, from the Gitaly node to some cloud storage. In contrary, because
bundles are stored elsewhere, some data is duplicated, and will cause increased
storage costs.

In this phase it's not the goal to boost performance for incremental
fetches. When the client has already cloned the repository, bundles won't be
used to optimize fetches new data.

Currently bundle-URI is not fully compatible with shallow clones, therefore
we'll leave that out of scope. More info about that in
[Git issue #170](https://gitlab.com/gitlab-org/git/-/issues/170).

## Proposal

When a client clones a repository, Gitaly advertises a bundle URI. This URI
points to a bundle that's refreshed on a regular interval, for example during
housekeeping. For each repository only one bundle will exist, so when a new one
is created, the old one is invalidated.

The bundles will be stored on a cloud Object Storage. To use bundles, the
administrator should configure this in Gitaly.

## Design and implementation details

When a client initiates a `git clone`, on the server-side Gitaly spawns a
`git upload-pack` process. Gitaly can pass along additional Git
configuration. To make `git upload-pack` advertise bundle URIs, it should pass
the following configuration:

- `uploadpack.advertiseBundleURIs` :: This should be set to `true` to enable to
  use of advertised bundles.
- `bundle.version` :: At the moment only `1` is accepted.
- `bundle.mode` :: This can be either `any` or `all`. Since we only want to use
  bundles for the initial clone, `any` is advised.
- `bundle.<id>.uri` :: This is the actual URI of the bundle identified with
  `<id>`. Initially we will only have one bundle per repository.

### Enable the use of advertised bundles on the client-side

The current version of Git does not use the advertised bundles by default when
cloning or fetching from a remote.
Luckily, we control most of the CI runners ourself. So to use bundle URI, we can
modify the Git configuration used by the runners and set
`transfer.bundleURI=true`.

### Access control

We don't want to leak data from private repositories through public HTTP(S)
hosts. There are a few options for how we can overcome this:

- Only activate the use of bundle-URI on public repositories.
- Use a solution like [signed-URLs](https://cloud.google.com/cdn/docs/using-signed-urls).

#### Public repositories only

Gitaly itself does not know if a project, and its repository, is public, so to
determine whether bundles can be used, GitLab Rails has to tell Gitaly. It's
complex to pass this information to Gitaly, and using this approach will make
the feature only available for public projects, so we will not proceed with this
solution.

#### Signed URLs

The use of [signed-URLs](https://cloud.google.com/cdn/docs/using-signed-urls) is
another option to control access to the bundles. This feature, provided by
Google Cloud, allows Gitaly to create a URI that has a short lifetime.

The downside to this approach is it depends on a feature that is
cloud-specific, so each cloud provider might provide such feature slightly
different, or not have it. But we want to roll this feature out on GitLab.com
first, which is hosted on Google Cloud, so for a first iteration we will use
this.

### Bundle creation

#### Use server-side backups

At the moment Gitaly knows how to back up repositories into bundles onto cloud
storage. The [documentation](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/gitaly-backup.md#user-content-server-side-backups)
describes how to use it.

For the initial implementation of bundle-URI we can piggy-back onto this
feature. An admin should create backups for the repositories they want to use
bundle-URI. With the existing configuration for backups, Gitaly can access cloud
storage.

#### As part of housekeeping

Gitaly has a housekeeping worker that daily looks for repositories to optimize.
Ideally we create a bundle right after the housekeeping (that is, garbage collection
and repacking) is done. This ensures the most optimal bundle file.

There are a few things to keep in mind when automatically creating bundles:

- **Does the bundle need to be recreated?** When there wasn't much activity on
  the repository it's probably not needed to create a new bundle file, as the
  client can fetch missing object directly from Gitaly anyway. The housekeeping
  tasks uses various heuristics to determine which strategy is taken for the
  housekeeping job, we can reuse parts of this logic in the creation of bundles.
- **Is it even needed to create a bundle?** Some repositories might be very
  small, or see very little activity. Creating a bundle for these, and
  duplicating it's data to object storage doesn't provide much value and only
  generates cost and maintenance.

#### Controlled by GitLab Rails

Because bundles increase the cost on storage, we eventually want to give the
GitLab administrator full control over the creation of bundles. To achieve this,
bundle-URI settings will be available on the GitLab admin interface. Here the
admin can configure per project which have bundle-URI enabled.

### Configuration

To use this feature, Gitaly needs to be configured. For this we'll add the
following settings to Gitaly's configuration file:

- `bundle_uri.strategy` :: This indicates which strategy should be used to
  create and serve bundle-URIs. At the moment the only supported value is
  "backups". When this setting to that value, Gitaly checks if a server-side
  backup is available and use that.
- `bundle_uri.sign_urls` :: When set to true, the cloud storage URLs are not
  passed to the client as-is, but are transformed into a signed URL. This
  setting is optional and only support Google Cloud Storage (for now).

The credentials to access cloud storage are reused as described in the Gitaly
Backups documentation.

### Storing metadata

For now all metadata needed to store bundles on the cloud is managed by Gitaly
server-side backups.

### Bundle cleanup

At some point the admin might decide to cleanup bundles for one or more
repositories, an admin command should be added for this. Because we're now only
using bundles created by `gitaly-backup`, we leave this out of scope.

### Gitaly Cluster compatibility

Creating server-side backups doesn't happen through Praefect at the moment. It's
up to the admin to address the nodes where they want to create backups from. If
they make sure the node is up-to-date, all nodes will have access to up-to-date
bundles and can pass proper bundle-URI parameters to the client. So no extra
work is needed to reuse server-side backup bundles with bundle-URI.

## Alternative Solutions

No alternative solutions are suggested at the moment.
