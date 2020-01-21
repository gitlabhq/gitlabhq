---
type: howto
---

# Geo nodes Admin Area **(PREMIUM ONLY)**

You can configure various settings for GitLab Geo nodes. For more information, see
[Geo documentation](../../administration/geo/replication/index.md).

On the primary node, go to **Admin Area > Geo**. On secondary nodes, go to **Admin Area > Geo > Nodes**.

## Common settings

All Geo nodes have the following settings:

| Setting | Description |
| --------| ----------- |
| Primary | This marks a Geo Node as **primary** node. There can be only one **primary** node; make sure that you first add the **primary** node and then all the others. |
| Name    | The unique identifier for the Geo node. Must match the setting `gitlab_rails['geo_node_name']` in `/etc/gitlab/gitlab.rb`. The setting defaults to `external_url` with a trailing slash. |
| URL     | The instance's user-facing URL. |

The node you're reading from is indicated with a green `Current node` label, and
the **primary** node is given a blue `Primary` label. Remember that you can only make
changes on the **primary** node!

## **Secondary** node settings

**Secondary** nodes have a number of additional settings available:

| Setting                   | Description |
|---------------------------|-------------|
| Selective synchronization | Enable Geo [selective sync](../../administration/geo/replication/configuration.md#selective-synchronization) for this **secondary** node. |
| Repository sync capacity  | Number of concurrent requests this **secondary** node will make to the **primary** node when backfilling repositories. |
| File sync capacity        | Number of concurrent requests this **secondary** node will make to the **primary** node when backfilling files. |

## Geo backfill

**Secondary** nodes are notified of changes to repositories and files by the **primary** node,
and will always attempt to synchronize those changes as quickly as possible.

Backfill is the act of populating the **secondary** node with repositories and files that
existed *before* the **secondary** node was added to the database. Since there may be
extremely large numbers of repositories and files, it's infeasible to attempt to
download them all at once, so GitLab places an upper limit on the concurrency of
these operations.

How long the backfill takes is a function of the maximum concurrency, but higher
values place more strain on the **primary** node. From [GitLab 10.2](https://gitlab.com/gitlab-org/gitlab/merge_requests/3107),
the limits are configurable. If your **primary** node has lots of surplus capacity,
you can increase the values to complete backfill in a shorter time. If it's
under heavy load and backfill is reducing its availability for normal requests,
you can decrease them.

## Using a different URL for synchronization

The **primary** node's Internal URL is used by **secondary** nodes to contact it
(to sync repositories, for example). The name Internal URL distinguishes it from
[External URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-the-external-url-for-gitlab)
which is used by users. Internal URL does not need to be a private address.

Internal URL defaults to External URL, but you can customize it under
**Admin Area > Geo > Nodes**.

CAUTION: **Warning:**
We recommend using an HTTPS connection while configuring the Geo nodes. To avoid
breaking communication between **primary** and **secondary** nodes when using
HTTPS, customize your Internal URL to point to a load balancer with TLS
terminated at the load balancer.

## Multiple secondary nodes behind a load balancer

In GitLab 11.11, **secondary** nodes can use identical external URLs as long as
a unique `name` is set for each Geo node. The `gitlab.rb` setting
`gitlab_rails['geo_node_name']` must:

- Be set for each GitLab instance that runs `unicorn`, `sidekiq`, or `geo_logcursor`.
- Match a Geo node name.

The load balancer must use sticky sessions in order to avoid authentication
failures and cross site request errors.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
