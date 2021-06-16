---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Grafana Configuration **(FREE SELF)**

[Grafana](https://grafana.com/) is a tool that enables you to visualize time
series metrics through graphs and dashboards. GitLab writes performance data to Prometheus,
and Grafana allows you to query the data to display useful graphs.

## Installation

Omnibus GitLab can [help you install Grafana (recommended)](https://docs.gitlab.com/omnibus/settings/grafana.html)
or Grafana supplies package repositories (Yum/Apt) for easy installation.
See [Grafana installation documentation](https://grafana.com/docs/grafana/latest/installation/)
for detailed steps.

Before starting Grafana for the first time, set the administration user
and password in `/etc/grafana/grafana.ini`. If you don't, the default password
is `admin`.

## Configuration

1. Log in to Grafana as the administration user.
1. Select **Data Sources** from the **Configuration** menu.
1. Select the **Add data source** button.
1. Select the required data source type. For example, [Prometheus](../prometheus/index.md#prometheus-as-a-grafana-data-source).
1. Complete the details for the data source and select the **Save & Test** button.

Grafana should indicate the data source is working.

## Import Dashboards

You can now import a set of default dashboards to start displaying useful information.
GitLab has published a set of default
[Grafana dashboards](https://gitlab.com/gitlab-org/grafana-dashboards) to get you started. To use
them:

1. Clone the repository, or download a ZIP file or tarball.
1. Follow these steps to import each JSON file individually:

   1. Log in to Grafana as the administration user.
   1. Select **Manage** from the **Dashboards** menu.
   1. Select the **Import** button, then the **Upload JSON file** button.
   1. Locate the JSON file to import and select **Choose for Upload**. Select the **Import** button.
   1. After the dashboard is imported, select the **Save dashboard** icon in the top bar.

If you don't save the dashboard after importing it, the dashboard is removed
when you navigate away from the page. Repeat this process for each dashboard you wish to import.

Alternatively, you can import all the dashboards into your Grafana
instance. For more information about this process, see the
[README of the Grafana dashboards](https://gitlab.com/gitlab-org/grafana-dashboards)
repository.

## Integration with GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/61005) in GitLab 12.1.

After setting up Grafana, you can enable a link to access it easily from the
GitLab sidebar:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Metrics and profiling**
   and expand **Metrics - Grafana**.
1. Check the **Enable access to Grafana** checkbox.
1. Configure the **Grafana URL**:
   - *If Grafana is enabled through Omnibus GitLab and on the same server,*
     leave **Grafana URL** unchanged. It should be `/-/grafana`.
   - *Otherwise,* enter the full URL of the Grafana instance.
1. Click **Save changes**.

GitLab displays your link in the **Menu > Admin > Monitoring > Metrics Dashboard**.

## Security Update

Users running GitLab version 12.0 or later should immediately upgrade to one of the
following security releases due to a known vulnerability with the embedded Grafana dashboard:

- 12.0.6
- 12.1.6

After upgrading, the Grafana dashboard is disabled, and the location of your
existing Grafana data is changed from `/var/opt/gitlab/grafana/data/` to
`/var/opt/gitlab/grafana/data.bak.#{Date.today}/`.

To prevent the data from being relocated, you can run the following command prior to upgrading:

```shell
echo "0" > /var/opt/gitlab/grafana/CVE_reset_status
```

To reinstate your old data, move it back into its original location:

```shell
sudo mv /var/opt/gitlab/grafana/data.bak.xxxx/ /var/opt/gitlab/grafana/data/
```

However, you should **not** reinstate your old data _except_ under one of the following conditions:

1. If you're certain that you changed your default administration password when you enabled Grafana.
1. If you run GitLab in a private network, accessed only by trusted users, and your
   Grafana login page has not been exposed to the internet.

If you require access to your old Grafana data but don't meet one of these criteria, you may consider:

1. Reinstating it temporarily.
1. [Exporting the dashboards](https://grafana.com/docs/grafana/latest/reference/export_import/#exporting-a-dashboard) you need.
1. Refreshing the data and [re-importing your dashboards](https://grafana.com/docs/grafana/latest/reference/export_import/#importing-a-dashboard).

WARNING:
These actions pose a temporary vulnerability while your old Grafana data is in use.
Deciding to take any of these actions should be weighed carefully with your need to access
existing data and dashboards.

For more information and further mitigation details, please refer to our
[blog post on the security release](https://about.gitlab.com/releases/2019/08/12/critical-security-release-gitlab-12-dot-1-dot-6-released/).

Read more on:

- [Introduction to GitLab Performance Monitoring](index.md)
- [GitLab Configuration](gitlab_configuration.md)
