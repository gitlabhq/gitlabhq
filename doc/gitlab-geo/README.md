# GitLab Geo

> **Notes:**
- This feature was introduced in GitLab Enterprise Edition 8.5 as Alpha.
  We recommend you use with at least GitLab Enterprise Edition 8.6.
- GitLab Geo is part of [GitLab Enterprise Edition Premium][ee].

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
this **exact order**:

1. Follow the first 3 steps to [install GitLab Enterprise Edition][install-ee]
   on the server that will serve as the secondary Geo node. Do not login or
   set up anything else in the secondary node for the moment.
1. [Setup the database replication](database.md)  (`primary <-> secondary (read-only)` topology)
1. [Configure GitLab](configuration.md) to set the primary and secondary nodes.

## After setup

After you set up the database replication and configure the GitLab Geo nodes,
there are a few things to consider:

1. When you create a new project in the primary node, the Git repository will
   appear in the secondary only _after_ the first `git push`.
1. You need an extra step to be able to fetch code from the `secondary` and push
   to `primary`:

     1. Clone your repository as you would normally do from the `secondary` node
     1. Change the remote push URL following this example:

         ```bash
         git remote set-url --push origin git@primary.gitlab.example.com:user/repo.git
         ```

>**Important**:
The initialization of a new Geo secondary node on versions older than 8.14
requires data to be copied from the primary, as there is no backfill
feature bundled with those versions.
See more details in the [Configure GitLab](configuration.md) step.

## Current limitations

- You cannot push code to secondary nodes
- Git LFS is not supported yet
- Primary node has to be online for OAuth login to happen (existing sessions and git are not affected)

## Frequently Asked Questions

Read more in the [Geo FAQ](faq.md).

[ee]: https://about.gitlab.com/gitlab-ee/ "GitLab Enterprise Edition landing page"
[install-ee]: https://about.gitlab.com/downloads-ee/ "GitLab Enterprise Edition Omnibus packages downloads page"
