---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Sourcegraph
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

NOTE:
On GitLab.com, this feature is available for public projects only.

[Sourcegraph](https://sourcegraph.com) provides code intelligence features in the GitLab UI.
When enabled, participating projects display a code intelligence popover in
these code views:

- Merge request diffs
- Commit view
- File view

When visiting one of these views, hover over a code reference to see a popover with:

- Details on how this reference was defined.
- **Go to definition**, which goes to the line of code where this reference was defined.
- **Find references**, which goes to the configured Sourcegraph instance, showing a list of references to the highlighted code.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, watch the video [Sourcegraph's new GitLab native integration](https://www.youtube.com/watch?v=LjVxkt4_sEA).
<!-- Video published on 2019-11-12 -->

For more information, see [epic 2201](https://gitlab.com/groups/gitlab-org/-/epics/2201).

## Set up for GitLab Self-Managed

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Prerequisites:

- You must have a Sourcegraph instance [configured and running](https://sourcegraph.com/docs/admin)
  with your GitLab instance as an external service.
- If your Sourcegraph instance uses a HTTPS connection to GitLab, you must
  [configure HTTPS](https://sourcegraph.com/docs/admin/http_https_configuration)
  for your Sourcegraph instance.

In Sourcegraph:

1. Go to the **Site admin** area.
1. Optional. [Configure your GitLab external service](https://sourcegraph.com/docs/admin/code_hosts/gitlab).
   If your GitLab repositories are already searchable in Sourcegraph, you can skip this step.
1. Confirm that you can search your repositories from GitLab in your Sourcegraph instance by running a test query.
1. Add your GitLab instance URL to the [`corsOrigin` setting](https://sourcegraph.com/docs/admin/config/site_config#corsOrigin)
   in your Sourcegraph configuration.

Next, configure your GitLab instance to connect to your Sourcegraph instance.

### Configure your GitLab instance with Sourcegraph

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Sourcegraph**.
1. Select **Enable Sourcegraph**.
1. Optional. Select **Block on private and internal projects**.
1. Set the **Sourcegraph URL** to your Sourcegraph instance, such as `https://sourcegraph.example.com`.
1. Select **Save changes**.

## Enable Sourcegraph in user preferences

Users on GitLab Self-Managed must also configure their user settings to use the
Sourcegraph integration.

On GitLab.com, the integration is available for all public projects.
Private projects are not supported.

Prerequisites:

- For GitLab Self-Managed, Sourcegraph must be enabled.

To enable this feature in your GitLab user preferences:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Integrations** section. Under **Sourcegraph**, select **Enable integrated code intelligence on code views**.
1. Select **Save changes**.

## References

- [Privacy information](https://sourcegraph.com/docs/integration/browser_extension/references/privacy) in the Sourcegraph documentation

## Troubleshooting

### Sourcegraph is not working

If you enabled Sourcegraph for your project but it is not working, Sourcegraph might not
have indexed the project yet. You can check if Sourcegraph is available for your project
by visiting `https://sourcegraph.com/gitlab.com/<project-path>`, replacing `<project-path>`
with the path to your GitLab project.
