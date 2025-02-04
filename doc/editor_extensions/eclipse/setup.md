---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in Eclipse."
title: Install and set up GitLab for Eclipse
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Experiment

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
The development, release, and timing of any products, features, or functionality may be subject to change or delay and remain at the
sole discretion of GitLab Inc.

## Add the GitLab Releases software site

To add the stable GitLab Releases software site:

1. In your IDE, select **Eclipse > Settings...**.
1. On the left sidebar, expand **Install/Update**, then select **Available Software Sites**.
1. On the right, select **Add...** to configure a new software site.
1. For **Name:**, use `GitLab Releases`.
1. For **Location:**, copy and paste the following URL:

   ```plaintext
   https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/releases/permalink/latest/downloads/
   ```

1. Select **Add**.
1. Select **Apply and Close**.

## Install the GitLab for Eclipse plugin

Prerequisites:

- Eclipse **4.33** and later.
- GitLab version 16.8 or later.

To install GitLab for Eclipse:

1. In your IDE, select the **Help** menu.
1. Select **Install New Software...**.
1. Expand **Work with:**, then select the `GitLab Releases` software site.
1. Select **Show only software applicable to target environment**.
1. Select the **GitLab** category to install the GitLab for Eclipse plugin and dependencies.
1. Select **Next >**, then select **Finish**.
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
