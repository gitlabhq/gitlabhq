---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Polling configuration

The GitLab UI polls for updates for different resources (issue notes, issue
titles, pipeline statuses, etc.) on a schedule appropriate to the resource.

In **[Admin Area](../user/admin_area/index.md) > Settings > Preferences > Real-time features**,
you can configure "Polling
interval multiplier". This multiplier is applied to all resources at once,
and decimal values are supported. For the sake of the examples below, we will
say that issue notes poll every 2 seconds, and issue titles poll every 5
seconds; these are _not_ the actual values.

- 1 is the default, and recommended for most installations. (Issue notes poll
  every 2 seconds, and issue titles poll every 5 seconds.)
- 0 will disable UI polling completely. (On the next poll, clients will stop
  polling for updates.)
- A value greater than 1 will slow polling down. If you see issues with
  database load from lots of clients polling for updates, increasing the
  multiplier from 1 can be a good compromise, rather than disabling polling
  completely. (For example: If this is set to 2, then issue notes poll every 4
  seconds, and issue titles poll every 10 seconds.)
- A value between 0 and 1 will make the UI poll more frequently (so updates
  will show in other sessions faster), but is **not recommended**. 1 should be
  fast enough. (For example, if this is set to 0.5, then issue notes poll every
  1 second, and issue titles poll every 2.5 seconds.)
