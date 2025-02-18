---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Connect and use GitLab Duo in Eclipse.
title: Install and set up GitLab for Eclipse
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< alert type="disclaimer" />}}

## Install the GitLab for Eclipse plugin

Prerequisites:

- Eclipse **4.33** and later.
- GitLab version 16.8 or later.

To install GitLab for Eclipse:

1. Open your Eclipse IDE and your preferred web browser.
1. In your web browser, go to the page for the
   [GitLab for Eclipse plugin](https://marketplace.eclipse.org/content/gitlab-eclipse) in the Eclipse Marketplace.
1. On the plugin's page, select **Install**, and drag your mouse over to your Eclipse IDE.
1. In the **Eclipse Marketplace** window, select the **GitLab For Eclipse** category.
1. Select **Confirm >**, then select **Finish**.
1. If the **Trust Authorities** window appears, select the **[`https://gitlab.com`](https://gitlab.com)** update site and select **Trust Selected**.
1. Select **Restart Now**.

## Connect to GitLab

After you install the extension, connect it to your GitLab account.

### Create a personal access token

If you are on a GitLab Self-Managed instance, create a personal access token.

1. In GitLab, on the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access tokens**.
1. Select **Add new token**.
1. Enter a name, description, and expiration date.
1. Select the `api` scope.
1. Select **Create personal access token**.

### Authenticate with GitLab

After you configure the plugin in your IDE, connect it to your GitLab account:

1. In your IDE, select **Eclipse > Settings...**.
1. On the left sidebar, select **GitLab**.
1. Provide the **Connection URL**. For GitLab.com, use `https://gitlab.com`.
1. For **GitLab Personal Access Token**, paste in the personal access token you created.
   The token is displayed while being entered for the first time. After applying, the
   token is not displayed and stored using the Eclipse secure storage.
1. Under the GitLab settings, select **Apply**.
1. Select **Apply and Close**.
