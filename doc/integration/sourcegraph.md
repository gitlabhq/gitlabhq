---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Sourcegraph

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16556) in GitLab 12.5 [with a flag](../administration/feature_flags.md) named `sourcegraph`. Disabled by default.
> - Enabled on GitLab.com in GitLab 12.5.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/73116) in GitLab 14.8.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, an administrator can [disable the feature flag](../administration/feature_flags.md) named `sourcegraph`.
On GitLab.com, this feature is available for public projects only.

[Sourcegraph](https://sourcegraph.com) provides code intelligence features, natively integrated into the GitLab UI.

For GitLab.com users, see [Sourcegraph for GitLab.com](#sourcegraph-for-gitlabcom).

![Sourcegraph demo](img/sourcegraph_demo_v12_5.png)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, watch the video [Sourcegraph's new GitLab native integration](https://www.youtube.com/watch?v=LjVxkt4_sEA).

NOTE:
This feature requires user opt-in. After Sourcegraph has been enabled for your GitLab instance,
you can choose to enable Sourcegraph [through your user preferences](#enable-sourcegraph-in-user-preferences).

## Set up for self-managed GitLab instances

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

Before you can enable Sourcegraph code intelligence in GitLab you must:
configure a Sourcegraph instance with your GitLab instance as an external service.

### Set up a self-managed Sourcegraph instance

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

If you are new to Sourcegraph, head over to the [Sourcegraph installation documentation](https://docs.sourcegraph.com/admin) and get your instance up and running.

If you are using an HTTPS connection to GitLab, you must [configure HTTPS](https://docs.sourcegraph.com/admin/http_https_configuration) for your Sourcegraph instance.

### Connect your Sourcegraph instance to your GitLab instance

1. Go to the site Admin Area in Sourcegraph.
1. [Configure your GitLab external service](https://docs.sourcegraph.com/admin/external_service/gitlab).
   You can skip this step if you already have your GitLab repositories searchable in Sourcegraph.
1. Validate that you can search your repositories from GitLab in your Sourcegraph instance by running a test query.
1. Add your GitLab instance URL to the [`corsOrigin` setting](https://docs.sourcegraph.com/admin/config/site_config#corsOrigin) in your site configuration.

### Configure your GitLab instance with Sourcegraph

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand the **Sourcegraph** configuration section.
1. Check **Enable Sourcegraph**.
1. Set the Sourcegraph URL to your Sourcegraph instance, such as `https://sourcegraph.example.com`.

![Sourcegraph administration settings](img/sourcegraph_admin_v12_5.png)

## Enable Sourcegraph in user preferences

If a GitLab administrator has enabled Sourcegraph, you can enable this feature in your user preferences.

In GitLab:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. In the **Integrations** section, select the checkbox under **Sourcegraph**.
1. Select **Save changes**.

![Sourcegraph user preferences](img/sourcegraph_user_preferences_v12_5.png)

## Using Sourcegraph code intelligence

Once enabled, participating projects display a code intelligence popover available in
the following code views:

- Merge request diffs
- Commit view
- File view

When visiting one of these views, you can now hover over a code reference to see a popover with:

- Details on how this reference was defined.
- **Go to definition**, which goes to the line of code where this reference was defined.
- **Find references**, which goes to the configured Sourcegraph instance, showing a list of references to the highlighted code.

![Sourcegraph demo](img/sourcegraph_popover_v12_5.png)

## Sourcegraph for GitLab.com

Sourcegraph is available for all public projects on GitLab.com.
Private projects are not supported.
For more information, see [epic 2201](https://gitlab.com/groups/gitlab-org/-/epics/2201).

## Sourcegraph and privacy

See the [Sourcegraph browser extension documentation](https://docs.sourcegraph.com/integration/browser_extension/references/privacy).

## Troubleshooting

### Sourcegraph isn't working

If you enabled Sourcegraph for your project but it isn't working, Sourcegraph may not have indexed the project yet. You can check if Sourcegraph is available for your project by visiting `https://sourcegraph.com/gitlab.com/<project-path>`replacing `<project-path>` with the path to your GitLab project.
