---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Polling configuration **(FREE SELF)**

The GitLab UI polls for updates for different resources (issue notes, issue
titles, pipeline statuses, and so on) on a schedule appropriate to the resource.

To configure the polling interval multiplier:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Real-time features**.
1. Set a value for the polling interval multiplier. This multiplier is applied
   to all resources at once, and decimal values are supported:

   - `1.0` is the default, and recommended for most installations.
   - `0` disables UI polling completely. On the next poll, clients stop
     polling for updates.
   - A value greater than `1` slows polling down. If you see issues with
     database load from lots of clients polling for updates, increasing the
     multiplier from 1 can be a good compromise, rather than disabling polling
     completely. For example, if you set the value to `2`, all polling intervals
     are multiplied by 2, which means that polling happens half as frequently.
   - A value between `0` and `1` makes the UI poll more frequently (so updates
     show in other sessions faster), but is **not recommended**. `1` should be
     fast enough.

1. Select **Save changes**.
