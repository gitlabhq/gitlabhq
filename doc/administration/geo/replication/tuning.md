---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: Tuning Geo
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can limit the number of concurrent operations the sites can run
in the background.

## Changing the sync/verification concurrency values

On the **primary** site:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Geo** > **Sites**.
1. Select **Edit** of the secondary site you want to tune.
1. Under **Tuning settings**, there are several variables that can be tuned to
   improve the performance of Geo:

   - Repository synchronization concurrency limit
   - File synchronization concurrency limit
   - Container repositories synchronization concurrency limit
   - Verification concurrency limit

Increasing the concurrency values increases the number of jobs that are scheduled.
However, this may not lead to more downloads in parallel unless the number of
available Sidekiq threads is also increased. For example, if repository synchronization
concurrency is increased from 25 to 50, you may also want to increase the number
of Sidekiq threads from 25 to 50. See the
[Sidekiq concurrency documentation](../../sidekiq/extra_sidekiq_processes.md#concurrency)
for more details.

## Tuning low default settings

To avoid excessive load when setting up new Geo sites, starting with GitLab 18.0,
Geo's concurrency settings are set to low defaults for most environments.
To increase these settings:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Geo** > **Sites**.
1. Decide which data types are progressing too slowly.
1. Watch load metrics of the primary and secondary sites.
1. Increase concurrency limits by 10 to be conservative.
1. Watch changes in progress and load metrics for at least 3 minutes.
1. Repeat increasing the limits until either load metrics reach your desired maximum, or syncing and verification is progressing as quickly as desired.

## Repository re-verification

See
[Automatic background verification](../disaster_recovery/background_verification.md).
