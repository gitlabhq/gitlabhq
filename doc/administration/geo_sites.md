---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Geo sites Admin Area

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

You can configure various settings for GitLab Geo sites. For more information, see
[Geo documentation](../administration/geo/index.md).

On either the primary or secondary site:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Geo > Sites**.

## Common settings

All Geo sites have the following settings:

| Setting | Description |
| --------| ----------- |
| Primary | This marks a Geo site as **primary** site. There can be only one **primary** site. |
| Name    | The unique identifier for the Geo site. It's highly recommended to use a physical location as a name. Good examples are "London Office" or "us-east-1". Avoid words like "primary", "secondary", "Geo", or "DR". This makes the failover process easier because the physical location does not change, but the Geo site role can. All nodes in a single Geo site use the same site name. Nodes use the `gitlab_rails['geo_node_name']` setting in `/etc/gitlab/gitlab.rb` to lookup their Geo site record in the PostgreSQL database. If `gitlab_rails['geo_node_name']` is not set, the node's `external_url` with trailing slash is used as fallback. The value of `Name` is case-sensitive, and most characters are allowed. |
| URL     | The instance's user-facing URL. |

The site you're currently browsing is indicated with a blue `Current` label, and
the **primary** node is listed first as `Primary site`.

## Secondary site settings

**Secondary** sites have a number of additional settings available:

| Setting                   | Description |
|---------------------------|-------------|
| Selective synchronization | Enable Geo [selective sync](../administration/geo/replication/configuration.md#selective-synchronization) for this **secondary** site. |
| Repository sync capacity  | Number of concurrent requests this **secondary** site makes to the **primary** site when backfilling repositories. |
| File sync capacity        | Number of concurrent requests this **secondary** site makes to the **primary** site when backfilling files. |

## Geo backfill

**Secondary** sites are notified of changes to repositories and files by the **primary** site,
and always attempt to synchronize those changes as quickly as possible.

Backfill is the act of populating the **secondary** site with repositories and files that
existed *before* the **secondary** site was added to the database. Because there may be
extremely large numbers of repositories and files, it's not feasible to attempt to
download them all at once; so, GitLab places an upper limit on the concurrency of
these operations.

How long the backfill takes is dependent on the maximum concurrency, but higher
values place more strain on the **primary** site. The limits are configurable.
If your **primary** site has lots of surplus capacity,
you can increase the values to complete backfill in a shorter time. If it's
under heavy load and backfill reduces its availability for standard requests,
you can decrease them.

## Set up the internal URLs

> - Setting up internal URLs in secondary sites was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77179) in GitLab 14.7.

You can set up a different URL for synchronization between the primary and secondary site.

The **primary** site's Internal URL is used by **secondary** sites to contact it
(to sync repositories, for example). The name Internal URL distinguishes it from
[External URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-the-external-url-for-gitlab),
which is used by users. Internal URL does not need to be a private address.

When [Geo secondary proxying](../administration/geo/secondary_proxy/index.md) is enabled,
the primary uses the secondary's internal URL to contact it directly.

The internal URL defaults to external URL. To change it:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Geo > Sites**.
1. Select **Edit** on the site you want to customize.
1. Edit the internal URL.
1. Select **Save changes**.

When enabled, the Admin Area for Geo shows replication details for each site directly
from the primary site's UI, and through the Geo secondary proxy, if enabled.

WARNING:
We recommend using an HTTPS connection while configuring the Geo sites. To avoid
breaking communication between **primary** and **secondary** sites when using
HTTPS, customize your Internal URL to point to a load balancer with TLS
terminated at the load balancer.

WARNING:
Starting with GitLab 13.3 and [until 13.11](https://gitlab.com/gitlab-org/gitlab/-/issues/325522),
if you use an internal URL that is not accessible to the users, the
OAuth authorization flow does not work properly, because users are redirected
to the internal URL instead of the external one.

## Multiple secondary sites behind a load balancer

**Secondary** sites can use identical external URLs if
a unique `name` is set for each Geo site. The `gitlab.rb` setting
`gitlab_rails['geo_node_name']` must:

- Be set for each GitLab instance that runs `puma`, `sidekiq`, or `geo_logcursor`.
- Match a Geo site name.

The load balancer must use sticky sessions to avoid authentication
failures and cross-site request errors.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
