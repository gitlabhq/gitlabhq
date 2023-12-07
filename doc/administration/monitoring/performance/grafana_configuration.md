---
stage: Service Management
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure Grafana **(FREE SELF)**

> - Grafana bundled with GitLab was [deprecated](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772) in GitLab 16.0.
> - Grafana bundled with GitLab was [removed](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772) in GitLab 16.3.

[Grafana](https://grafana.com/) is a tool that enables you to visualize time
series metrics through graphs and dashboards. GitLab writes performance data to Prometheus,
and Grafana allows you to query the data to display graphs.

WARNING:
Grafana bundled with GitLab was deprecated GitLab 16.0 and [removed](#grafana-bundled-with-gitlab-removed) in GitLab 16.3.

## Import GitLab dashboards

You can import a set of default dashboards to start displaying information. GitLab has published a set of default
[Grafana dashboards](https://gitlab.com/gitlab-org/grafana-dashboards) to get you started. To use them:

1. Clone the repository, or download a ZIP file or tarball.
1. Follow these steps to [import each dashboard JSON file individually](https://grafana.com/docs/grafana/latest/dashboards/manage-dashboards/#import-a-dashboard)

Alternatively, you can import all the dashboards into your Grafana instance. For more information about this process,
see the [GitLab Grafana dashboards](https://gitlab.com/gitlab-org/grafana-dashboards).

## Integrate with GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/61005) in GitLab 12.1.

After setting up Grafana, you can enable a link to access it from the
GitLab sidebar:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. On the left sidebar, select **Settings > Metrics and profiling**
   and expand **Metrics - Grafana**.
1. Select the **Add a link to Grafana** checkbox.
1. Configure the **Grafana URL**. Enter the full URL of the Grafana instance.
1. Select **Save changes**.

GitLab displays your link in the Admin Area under **Monitoring > Metrics Dashboard**.

## Required Scopes

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5822) in GitLab 13.10.

When setting up Grafana through the process above, no scope shows in the screen in
the Admin Area under **Applications > GitLab Grafana**. However, the `read_user` scope is
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

<!--- start_remove The following content will be removed on remove_date: '2023-12-22' -->

## Grafana bundled with GitLab (removed)

Grafana bundled with GitLab was an optional service for Linux package installations that provided a user interface to
GitLab metrics.

The version of Grafana that is bundled with Linux package installations is no longer supported. If you're using the
Grafana that came bundled with GitLab, you should switch to a newer version from [Grafana Labs](https://grafana.com/grafana/).

### Switch to new Grafana instance

To switch away from bundled Grafana to a newer version of Grafana from Grafana Labs:

1. Set up a version of Grafana from Grafana Labs.
1. [Export the existing dashboards](https://grafana.com/docs/grafana/latest/dashboards/manage-dashboards/#export-a-dashboard) from bundled Grafana.
1. [Import the existing dashboards](https://grafana.com/docs/grafana/latest/dashboards/manage-dashboards/#import-a-dashboard) in the new Grafana instance.
1. [Configure GitLab](#integrate-with-gitlab-ui) to use the new Grafana instance.

<!--- end_remove -->
