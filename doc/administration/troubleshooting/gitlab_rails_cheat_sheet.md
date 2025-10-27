---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Rails Console Cheat Sheet
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This was the GitLab Support Team's collection of information regarding the GitLab Rails
console, for use while troubleshooting. It is listed here for posterity,
as most content has been moved to feature-specific troubleshooting pages and sections,
see epic [&8147](https://gitlab.com/groups/gitlab-org/-/epics/8147#tree).
You may want to update your bookmarks accordingly.

If you are currently having an issue with GitLab,
it is highly recommended that you first check
our guide on [the Rails console](../operations/rails_console.md),
and your [support options](https://about.gitlab.com/support/),
before attempting the information pointed to from here.

{{< alert type="warning" >}}

Some of these scripts could be damaging if not run correctly,
or under the right conditions. We highly recommend running them under the
guidance of a Support Engineer, or running them in a test environment with a
backup of the instance ready to be restored, just in case.

{{< /alert >}}

{{< alert type="warning" >}}

As GitLab changes, changes to the code are inevitable,
and so some scripts may not work as they once used to. These are not kept
up-to-date as these scripts/commands were added as they were found/needed. As
mentioned previously, we recommend running these scripts under the supervision of a
Support Engineer, who can also verify that they continue to work as they
should and, if needed, update the script for the latest version of GitLab.
{{< /alert >}}

## Mirrors

### Find mirrors with `bad decrypt` errors

This content has been converted to a Rake task, see [verify database values can be decrypted using the current secrets](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

### Transfer mirror users and tokens to a single service account

This content has been moved to [Troubleshooting Repository mirroring](../../user/project/repository/mirror/troubleshooting.md#transfer-mirror-users-and-tokens-to-a-single-service-account).

## Merge requests

## CI

This content has been moved to [CI/CD maintenance](../cicd/maintenance.md).

## License

This content has been moved to [Activate GitLab EE with a license file or key](../license_file.md).

## Registry

### Registry Disk Space Usage by Project

To view storage space by project in the container registry, see [Registry Disk Space Usage by Project](../packages/container_registry.md#registry-disk-space-usage-by-project).

### Run the cleanup policy

To reduce storage space in the container registry, see [Run the cleanup policy](../packages/container_registry.md#run-the-cleanup-policy).

## Sidekiq

This content has been moved to [Troubleshooting Sidekiq](../sidekiq/sidekiq_troubleshooting.md).

## Geo

### Reverify all uploads (or any SSF data type which is verified)

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting/synchronization_verification.md#resync-and-reverify-multiple-components).

### Artifacts

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

### Repository verification failures

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

### Resync repositories

Moved to [Geo replication troubleshooting - Resync repository types](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

Moved to [Geo replication troubleshooting - Resync project and project wiki repositories](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

### Blob types

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

## Generate Service Ping

This content has been moved to Troubleshooting Service Ping in the GitLab development documentation.
