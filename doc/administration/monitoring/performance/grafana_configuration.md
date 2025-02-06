---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure Grafana
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - Grafana bundled with GitLab was [deprecated](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772) in GitLab 16.0.
> - Grafana bundled with GitLab was [removed](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772) in GitLab 16.3.

[Grafana](https://grafana.com/) is a tool that enables you to visualize time
series metrics through graphs and dashboards. GitLab writes performance data to Prometheus,
and Grafana allows you to query the data to display graphs.

## Integrate with GitLab UI

After setting up Grafana, you can enable a link to access it from the
GitLab sidebar:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Metrics and profiling**.
1. Expand **Metrics - Grafana**.
1. Select the **Add a link to Grafana** checkbox.
1. Configure the **Grafana URL**. Enter the full URL of the Grafana instance.
1. Select **Save changes**.

GitLab displays your link in the **Admin** area under **Monitoring > Metrics Dashboard**.

## Required Scopes

When setting up Grafana through the process above, no scope shows in the screen in
the **Admin** area under **Applications > GitLab Grafana**. However, the `read_user` scope is
required and is provided to the application automatically. Setting any scope other than
`read_user` without also including `read_user` leads to this error when you try to sign in using
GitLab as the OAuth provider:

```plaintext
The requested scope is invalid, unknown, or malformed.
```

If you see this error, make sure that one of the following is true in the GitLab Grafana
configuration screen:

- No scopes appear.
- The `read_user` scope is included.
