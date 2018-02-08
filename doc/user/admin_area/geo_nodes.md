# Geo nodes admin area

For more information about setting up GitLab Geo, read the
[Geo documentation](../../gitlab-geo/README.md).

When you're done, you can navigate to **Admin area ➔ Geo nodes** (`/admin/geo_nodes`).

## Common settings

All Geo nodes have the following settings:

| Setting | Description |
| --------| ----------- |
| Primary | This marks a Geo Node as primary. There can be only one primary, make sure that you first add the primary node and then all the others. |
| URL     | The instance's full URL, in the same way it is configured in  `/etc/gitlab/gitlab.rb` (Omnibus GitLab installations) or `gitlab.yml` (source based installations). |

The node you're reading from is indicated with a green `Current node` label, and
the primary is given a blue `Primary` label. Remember that you can only make
changes on the primary!

## Secondary node settings

Secondaries have a number of additional settings available:

| Setting                   | Description |
|---------------------------|-------------|
| Selective synchronization | Enable Geo [selective sync](../../gitlab-geo/configuration.md#selective-synchronization) for this secondary. |
| Repository sync capacity  | Number of concurrent requests this secondary will make to the primary when backfilling repositories. |
| File sync capacity        | Number of concurrent requests this secondary will make to the primary when backfilling files. |

## Geo backfill

Secondaries are notified of changes to repositories and files by the primary,
and will always attempt to synchronize those changes as quickly as possible.

Backfill is the act of populating the secondary with repositories and files that
existed *before* the secondary was added to the database. Since there may be
extremely large numbers of repositories and files, it's infeasible to attempt to
download them all at once, so GitLab places an upper limit on the concurrency of
these operations.

How long the backfill takes is a function of the maximum concurrency, but higher
values place more strain on the primary node. From [GitLab 10.2](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3107),
the limits are configurable - if your primary node has lots of surplus capacity,
you can increase the values to complete backfill in a shorter time. If it's
under heavy load and backfill is reducing its availability for normal requests,
you can decrease them.
