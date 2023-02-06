---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
<!--- start_remove The following content will be removed on remove_date: '2023-08-22' -->
# Embed Grafana panels in Markdown (deprecated) **(FREE)**

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110290) in GitLab 15.9
and is planned for removal in 16.0. We intend to replace this feature with the ability to [embed charts](https://gitlab.com/groups/gitlab-org/opstrace/-/epics/33) with the [GitLab Observability UI](https://gitlab.com/gitlab-org/opstrace/opstrace-ui).
This change is a breaking change.

Grafana panels can be embedded in [GitLab Flavored Markdown](../../user/markdown.md). You can
embed Grafana panels using either:

- [Grafana-rendered images](#use-grafana-rendered-images).
- [Grafana API](#use-integration-with-grafana-api).

## Use Grafana-rendered images

You can embed live [Grafana](https://docs.gitlab.com/omnibus/settings/grafana.html) panels as
[a direct link](https://grafana.com/docs/grafana/v7.5/sharing/share-panel/#use-direct-link).
Your Grafana instance must:

- Be available to the target user, either as a public dashboard or on the same network.
- Have [Grafana Image Renderer](https://grafana.com/grafana/plugins/grafana-image-renderer/) installed.

To use Grafana-rendered images:

1. Go to the dashboard containing the panel in Grafana.
1. From the panel's menu, select **Share**.
1. Select **Direct link rendered image**, which provides the link.
1. Copy the link and add an image tag as [inline HTML](../../user/markdown.md#inline-html) in your
   Markdown in the format `<img src="your_link"/>`. You can tweak the query parameters to meet your needs, such as removing the `&from=`
   and `&to=` parameters to display a live panel.

## Use integration with Grafana API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31376) in GitLab 12.5.

Each project can support integration with one Grafana instance. This enables you to copy a link to a
panel in Grafana, then paste it into a GitLab Markdown field. The panel renders in the GitLab panel
format. To embed panels from a Grafana instance, the data source must be:

- A Prometheus instance.
- Proxyable, so the **HTTP > Access** setting for the Grafana data source should be set to
  **Server (default)**.

### Set up Grafana integration

To set up the Grafana API in Grafana:

1. In Grafana, [generate an Admin-level API Token](https://grafana.com/docs/grafana/next/developers/http_api/auth/#create-api-token).
1. In your GitLab project, go to **Settings > Monitor** and expand the **Grafana authentication**
   section.
1. To enable the integration, check the **Active** checkbox.
1. For **Grafana URL**, enter the base URL of the Grafana instance.
1. For **API Token**, enter the Administrator API token you just generated.
1. Select **Save Changes**.

NOTE:
If the Grafana integration is enabled, users with the Reporter role on public
projects and the Guest role on non-public projects can query metrics from the
Prometheus instance. All requests proxied through GitLab are authenticated with
the same Grafana Administrator API token.

### Generate a link to a panel

To generate a link to a panel:

1. In Grafana, go to the dashboard you wish to embed a panel from.
1. In the upper-left corner of the page, select a specific value for each variable required for the
   queries in the dashboard.
1. In Grafana select a panel's title, then select **Share** to open the panel's sharing dialog to
   the **Link** tab.

   If you select the dashboard's share button instead, GitLab attempts to embed the first supported
   panel on the dashboard (if available).
1. If your Prometheus queries use the Grafana custom template variables, ensure the
   **Template variables** option is set to on. Only the Grafana global template variables
   `$__interval`, `$__from`, and `$__to` are supported.
1. Set the **Current time range** option to on, to specify the time range of the panel. Otherwise,
   the default range is the last 8 hours.
1. Select **Copy** to copy the URL to the clipboard.
1. In GitLab, paste the URL into a Markdown field and save. The panel takes a few moments to render.

See the following example of a rendered panel.

![GitLab Rendered Grafana Panel](img/rendered_grafana_embed_v12_5.png)
<!--- end_remove -->
