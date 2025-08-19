---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Convert a Docker CE instance to EE
---

You can convert an existing GitLab Community Edition (CE) container for Docker
to a GitLab [Enterprise Edition](https://about.gitlab.com/pricing/) (EE) container
using the same approach as [upgrading the version](../docker/_index.md).

You should convert from the same version of CE to EE (for example, CE 18.1 to EE 18.1).
However, this is not required. Any standard upgrade (for example, CE 18.0 to EE 18.1) should work.
The following steps assume that you are converting to the same version.

1. Take a [backup](../../install/docker/backup.md). At minimum, back up [the database](../../install/docker/backup.md#create-a-database-backup) and
   the GitLab secrets file.

1. Stop the current CE container, and remove or rename it.

1. To create a new container with GitLab EE,
   replace `ce` with `ee` in your `docker run` command or `docker-compose.yml` file.
   Reuse the CE container name, port mappings, file mappings, and version.
