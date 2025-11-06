---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Connect and use GitLab Duo in Eclipse.
title: Install and set up GitLab for Eclipse
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163) from experiment to beta in GitLab 17.11.

{{< /history >}}

{{< alert type="disclaimer" />}}

## Install the GitLab for Eclipse plugin

Prerequisites:

- Eclipse 4.33 and later.
- GitLab version 16.8 or later.

To install GitLab for Eclipse:

1. Open your Eclipse IDE and your preferred web browser.
1. In your web browser, go to the page for the
   [GitLab for Eclipse plugin](https://marketplace.eclipse.org/content/gitlab-eclipse) in the Eclipse Marketplace.
1. On the plugin's page, select **Install**, and drag your mouse over to your Eclipse IDE.
1. In the **Eclipse Marketplace** window, select the **GitLab For Eclipse** category.
1. Select **Confirm >**, then select **Finish**.
1. If the **Trust Authorities** window appears, select the **`https://gitlab.com`** update site and select **Trust Selected**.
1. Select **Restart Now**.

If the Eclipse Marketplace is unavailable, follow the
[Eclipse installation instructions](https://help.eclipse.org/latest/index.jsp?topic=%2Forg.eclipse.platform.doc.user%2Ftasks%2Ftasks-124.htm)
for adding a new software site. For **Work with**, use
`https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/releases/permalink/latest/downloads/`.

## Connect to GitLab

After you install the extension, connect it to your GitLab account by creating a personal access token and authenticating with GitLab.

### Create a personal access token

If you are on a GitLab Self-Managed instance, create a personal access token.

1. In GitLab, on the left sidebar, select your avatar. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Edit profile**.
1. On the left sidebar, select **Personal access tokens**.
1. Select **Add new token**.
1. Enter a name, description, and expiration date.
1. Select the `api` scope.
1. Select **Create personal access token**.

### Authenticate with GitLab

After you configure the plugin in your IDE, connect it to your GitLab account:

1. In your IDE, select **Eclipse** > **Settings**.
1. On the left sidebar, select **GitLab**.
1. Provide the **Connection URL**. For GitLab.com, use `https://gitlab.com`.
1. For **GitLab Personal Access Token**, paste in the personal access token you created.
   The token is displayed while being entered for the first time. After applying, the
   token is not displayed and stored using the Eclipse secure storage.
1. Under the GitLab settings, select **Apply**.
1. Select **Apply and Close**.
