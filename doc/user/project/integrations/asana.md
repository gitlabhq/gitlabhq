---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Asana
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Support for V1 Asana URL format [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/523692) in GitLab 18.3.

{{< /history >}}

The Asana integration adds commit messages as comments to Asana tasks.
Once enabled, commit messages are checked for Asana task URLs (for example,
`https://app.asana.com/1/12345/project/67890/task/987654`) or task IDs starting with `#`
(for example, `#987654`). Every task ID found gets the commit comment added to it.

You can also close a task with a message containing: `fix #123456`.
You can use either of these words:

- `fix`
- `fixed`
- `fixes`
- `fixing`
- `close`
- `closes`
- `closed`
- `closing`

See also the [Asana integration API documentation](../../../api/project_integrations.md#asana).

## Setup

In Asana, create a personal access token.
[Learn about personal access tokens in Asana](https://developers.asana.com/docs/personal-access-token).

Complete these steps in GitLab:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Integrations**.
1. Select **Asana**.
1. Ensure that the **Active** toggle is enabled.
1. Paste the token you generated in Asana.
1. Optional. To restrict this setting to specific branches, list them in the **Restrict to branch**
   field, separated with commas.
1. Optional. Select **Test settings**.
1. Select **Save changes**.
