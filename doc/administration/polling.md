---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Polling interval multiplier
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The GitLab UI polls for updates for different resources (such as issue notes, issue titles, and pipeline
statuses) on a schedule appropriate to the resource.

Adjust the multiplier on these schedules to adjust how frequently the GitLab UI polls for updates. If
you set the multiplier to:

- A value greater than `1`, UI polling slows down. If you see issues with database load from lots of
  clients polling for updates, increasing the multiplier can be a good alternative to disabling
  polling completely. For example, if you set the value to `2`, all polling intervals
  are multiplied by 2, which means that polling happens half as frequently.
- A value between `0` and `1`, the UI polls more frequently so updates occur more frequently.
  **Not recommended**.
- `0`, all polling is disabled. On the next poll, clients stop polling for updates.

The default value (`1`) is recommended for the majority of GitLab installations.

## Configure

To adjust the polling interval multiplier:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Polling interval multiplier**.
1. Set a value for the polling interval multiplier. This multiplier is applied to all resources at
   once.
1. Select **Save changes**.
