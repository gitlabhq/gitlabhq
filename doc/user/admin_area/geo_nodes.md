# Geo nodes admin area **[PREMIUM ONLY]**

For more information about setting up GitLab Geo, read the
[Geo documentation](https://docs.gitlab.com/ee/administration/geo/replication/index.html).

When you're done, you can navigate to **Admin area > Geo** (`/admin/geo/nodes`).

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
 Selective synchronization | Enable Geo [selective sync](https://docs.gitlab.com/ee/administration/geo/replication/configuration.html#selective-synchronization) for this **secondary** node. |
| Repository sync capacity  | Number of concurrent requests this **secondary** node will make to the **primary** node when backfilling repositories. |
| File sync capacity        | Number of concurrent requests this **secondary** node will make to the **primary** node when backfilling files. |

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

## Using a different URL for synchronization

The **primary** node's Internal URL is used by **secondary** nodes to contact it
(to sync repositories, for example). The name Internal URL distinguishes it from
[External URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-the-external-url-for-gitlab)
which is used by users. Internal URL does not need to be a private address.

Internal URL defaults to External URL, but you can customize it under
**Admin area > Geo Nodes**.
