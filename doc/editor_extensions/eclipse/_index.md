---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connect and use GitLab Duo in Eclipse.
title: GitLab for Eclipse
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

The GitLab for Eclipse plugin integrates with GitLab Duo to offer the following features:

- [GitLab Duo Code Suggestions](../../user/project/repository/code_suggestions/_index.md)
- [GitLab Duo Non-Agentic Chat](../../user/gitlab_duo_chat/_index.md). Only available for GitLab Duo
  Pro or Enterprise, or GitLab Duo with Amazon Q users.

To install and configure the plugin, see [install and set up](setup.md).

## Update the plugin

To update your version of the plugin:

1. In your Eclipse IDE, go to **Help** > **Check for Updates**.
1. In the **Available Updates** dialog, ensure that **GitLab for Eclipse** is selected.
1. Select **Next**, then **Finish**, to update the plugin.

## Report issues with the plugin

You can report any issues, bugs, or feature requests in the
[`gitlab-eclipse-plugin` issue tracker](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues).
Use the `Bug` or `Feature Proposal` template.

## Related topics

- [GitLab for Eclipse releases](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/releases)
- [Security considerations for editor extensions](../security_considerations.md)
- [Eclipse troubleshooting](troubleshooting.md)
- [GitLab Language Server documentation](../language_server/_index.md)
- [Open issues for this plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/)
- [View source code](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin)
