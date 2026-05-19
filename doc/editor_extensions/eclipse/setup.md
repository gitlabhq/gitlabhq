---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connect and use GitLab Duo in Eclipse.
title: Install and set up GitLab for Eclipse
---

{{< details >}}

- Tier: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163) from experiment to beta in GitLab 17.11.
- Access to GitLab Duo Non-Agentic Chat removed for GitLab Duo Core customers on May 21, 2026 as part of GitLab 19.0, with a feature flag named `no_duo_classic_for_duo_core_users`. Enabled by default.

{{< /history >}}

> [!disclaimer]

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

## Authenticate with GitLab

After you install the plugin, authenticate and connect it to your GitLab account.

Prerequisites:

- A [personal access token](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) with the `api` scope.

To authenticate with GitLab:

1. In your IDE, open preferences:
   - For macOS, select **Eclipse** > **Settings**.
   - For Windows or Linux, select **Window** > **Preferences**.
1. In the left sidebar, select **GitLab Duo**.
1. Under **Connection**, enter the URL for your GitLab instance. For GitLab.com,
   use `https://gitlab.com`.
1. Under **Authentication**, enter your personal access token.
   Your token is hidden and stored using Eclipse secure storage.
1. Select **Verify Setup**.
1. Select **Apply and Close**.
