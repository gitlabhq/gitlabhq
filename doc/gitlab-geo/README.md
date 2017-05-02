# GitLab Geo

> **Notes:**
- GitLab Geo is part of [GitLab Enterprise Edition Premium][ee].
- Introduced in GitLab Enterprise Edition 8.9.
  We recommend you use it with at least GitLab Enterprise Edition 8.14.
- You should make sure that all nodes run the same GitLab version.

GitLab Geo allows you to replicate your GitLab instance to other geographical
locations as a read-only fully operational version.

## Overview

If you have two or more teams geographically spread out, but your GitLab
instance is in a single location, fetching large repositories can take a long
time.

Your Geo instance can be used for cloning and fetching projects, in addition to
reading any data. This will make working with large repositories over large
distances much faster.

![GitLab Geo overview](img/geo-overview.png)

When Geo is enabled, we refer to your original instance as a **primary** node
and the replicated read-only ones as **secondaries**.

Keep in mind that:

- Secondaries talk to primary to get user data for logins (API), and to
  clone/pull from repositories (HTTP(S)/SSH).
- Primary talks to secondaries to notify for changes (API).

## Setup instructions

In order to set up one or more GitLab Geo instances, follow the steps below in
the **exact order** they appear. **Make sure the GitLab version is the same on
all nodes.**

### Using Omnibus GitLab

If you installed GitLab using the Omnibus packages (highly recommended):

1. [Install GitLab Enterprise Edition][install-ee] on the server that will serve
   as the **secondary** Geo node. Do not login or set up anything else in the
   secondary node for the moment.
1. [Upload the GitLab License](../user/admin_area/license.md) you purchased for GitLab Enterprise Edition to unlock GitLab Geo.
1. [Setup the database replication](database.md)  (`primary (read-write) <-> secondary (read-only)` topology).
1. [Configure GitLab](configuration.md) to set the primary and secondary nodes.
1. [Follow the after setup steps](after_setup.md).

[install-ee]: https://about.gitlab.com/downloads-ee/ "GitLab Enterprise Edition Omnibus packages downloads page"

### Using GitLab installed from source

If you installed GitLab from source:

1. [Install GitLab Enterprise Edition][install-ee-source] on the server that
   will serve as the **secondary** Geo node. Do not login or set up anything
   else in the secondary node for the moment.
1. [Upload the GitLab License](../user/admin_area/license.md) you purchased for GitLab Enterprise Edition to unlock GitLab Geo.
1. [Setup the database replication](database_source.md)  (`primary (read-write) <-> secondary (read-only)` topology).
1. [Configure GitLab](configuration_source.md) to set the primary and secondary
   nodes.
1. [Follow the after setup steps](after_setup.md).

[install-ee-source]: https://docs.gitlab.com/ee/install/installation.html "GitLab Enterprise Edition installation from source"

## Updating the Geo nodes

Read how to [update your Geo nodes to the latest GitLab version](updating_the_geo_nodes.md).

## Current limitations

- You cannot push code to secondary nodes
- Primary node has to be online for OAuth login to happen (existing sessions and git are not affected)

## Frequently Asked Questions

Read more in the [Geo FAQ](faq.md).

## Troubleshooting

Read the [troubleshooting document](troubleshooting.md).

[ee]: https://about.gitlab.com/gitlab-ee/ "GitLab Enterprise Edition landing page"
[install-ee]: https://about.gitlab.com/downloads-ee/ "GitLab Enterprise Edition Omnibus packages downloads page"
[install-ee-source]: https://docs.gitlab.com/ee/install/installation.html "GitLab Enterprise Edition installation from source"
