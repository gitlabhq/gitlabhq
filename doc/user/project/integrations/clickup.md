---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ClickUp
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120732) in GitLab 16.1.

You can use [ClickUp](https://clickup.com/) as an external issue tracker.
To enable the ClickUp integration in a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **ClickUp**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Fill in the required fields:

   - **Project URL**: The URL to the ClickUp project to link to this GitLab project.
   - **Issue URL**: The URL to the ClickUp project issue to link to this GitLab project.
     The URL must contain `:id`. GitLab replaces this ID with the issue number.

1. Optional. Select **Test settings**.
1. Select **Save changes**.

After you have configured and enabled ClickUp, you see the ClickUp link on the GitLab project pages,
which takes you to your ClickUp project.

For example, this is a configuration for a project named `gitlab-ci`:

- Project URL: `https://app.clickup.com/1234567`
- Issue URL: `https://app.clickup.com/t/1234567/:id`

You can also disable [GitLab internal issue tracking](../issues/_index.md) in this project.
For more information about the steps and consequences of disabling GitLab issues, see
Configure project [visibility](../../public_access.md#change-project-visibility), [features, and permissions](../settings/_index.md#configure-project-features-and-permissions).

## Reference ClickUp issues in GitLab

You can reference your ClickUp issues using:

- `#<ID>`, where `<ID>` is a alphanumerical string (example `#8wrtcd932`).
- `CU-<ID>`, where `<ID>` is a alphanumerical string (example `CU-8wrtcd932`).
- `<PROJECT>-<ID>`, for example `API_32-143`, where:
  - `<PROJECT>` is a ClickUp list custom prefix ID.
  - `<ID>` is a number.
- If you use [Custom Task IDs](https://help.clickup.com/hc/en-us/sections/17044579323671-Custom-Task-IDs), the full custom task ID also works. For
  example `SOP-1234`.

In links, the `CU-` part is ignored and it links to the global URL of the issue. When a custom
prefix is used in a ClickUp list, the prefix part is part of the link.

We suggest using the `CU-` format (`CU-<ID>`) if you have both internal and external issue
trackers enabled. If you use the shorter format, and an issue with the same ID exists in the
internal issue tracker, the internal issue is linked.

For [Custom Task IDs](https://help.clickup.com/hc/en-us/sections/17044579323671-Custom-Task-IDs), you **must** include the full ID, including your custom prefix. For example, `SOP-1432`.
