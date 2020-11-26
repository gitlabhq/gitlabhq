---
type: reference, how-to
stage: Create
group: Editor
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
---

# Gitpod Integration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/228893) in GitLab 13.4.
> - It was [deployed behind a feature flag](#enable-or-disable-the-gitpod-integration), disabled by default.
> - [Became enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/258206) in GitLab 13.5.
> - It's enabled on GitLab.com.
> - It's recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#configure-your-gitlab-instance-with-gitpod). **(CORE ONLY)**

CAUTION: **Warning:**
This feature might not be available to you. Check the **version history** note above for details.

With [Gitpod](https://gitpod.io/) you can describe your dev environment as code to get fully set
up, compiled, and tested dev environments for any GitLab project. The dev environments are not only
automated but also prebuilt which means that Gitpod continuously builds your Git branches like a CI
server. By that you don’t have to wait for dependencies to be downloaded and builds to finish, but
you can start coding immediately.

In short: With Gitpod you can start coding instantly on any project, branch, and merge request from
any device, at any time.

![Gitpod interface](img/gitpod_web_interface_v13_4.png)

You can launch Gitpod directly from GitLab by clicking the **Gitpod** button from the **Web IDE**
dropdown on the project page:

![Gitpod Button on Project Page](img/gitpod_button_project_page_v13_4.png)

To learn more about Gitpod, see their [features](https://www.gitpod.io/features/) and
[documentation](https://www.gitpod.io/docs/).

To use the GitLab-Gitpod integration, you need to enable it from your user preferences:

1. From the GitLab UI, click your avatar in the top-right corner, then click **Settings**.
1. On the left-hand nav, click **Preferences**.
1. Under **Integrations**, find the **Gitpod** section.
1. Check **Enable Gitpod**.

Users of GitLab.com can enable it and start using straightaway. Users of GitLab self-managed instances
can follow the same steps once the integration has been enabled and configured by a GitLab administrator.

## Configure your GitLab instance with Gitpod **(CORE ONLY)**

If you are new to Gitpod, head over to the [Gitpod documentation](https://www.gitpod.io/docs/self-hosted/latest/self-hosted/)
and get your instance up and running.

1. In GitLab, go to **Admin Area > Settings > General**.
1. Expand the **Gitpod** configuration section.
1. Check **Enable Gitpod**.
1. Add your Gitpod instance URL (for example, `https://gitpod.example.com`).

## Enable or disable the Gitpod integration **(CORE ONLY)**

The Gitpod integration is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can enable or disable it.

To disable it:

```ruby
Feature.disable(:gitpod)
```

To enable it:

```ruby
Feature.enable(:gitpod)
```
