---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Incident management rate limits
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

You can limit the number of inbound alerts for [incidents](../../operations/incident_management/incidents.md)
that can be created in a period of time. The inbound [incident management](../../operations/incident_management/_index.md)
alert limit can help prevent overloading your incident responders by reducing the
number of alerts or duplicate issues.

As an example, if you set a limit of `10` requests every `60` seconds,
and `11` requests are sent to an [alert integration endpoint](../../operations/incident_management/integrations.md) within one minute,
the eleventh request is blocked. Access to the endpoint is allowed again after one minute.

This limit is:

- Applied independently per project.
- Not applied per IP address.
- Disabled by default.

Requests that exceed the limit are logged into `auth.log`.

## Set a limit on inbound alerts

To set inbound incident management alert limits:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Incident Management Limits**.
1. Select the **Enable Incident Management inbound alert limit** checkbox.
1. Optional. Input a custom value for **Maximum requests per project per rate limit period**. Default is 3600.
1. Optional. Input a custom value for **Rate limit period**. Default is 3600 seconds.
