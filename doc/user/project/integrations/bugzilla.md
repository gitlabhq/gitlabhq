---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Bugzilla
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

[Bugzilla](https://www.bugzilla.org/) is a web-based general-purpose bug tracking system and testing
tool.

You can configure Bugzilla as an
[external issue tracker](../../../integration/external-issue-tracker.md) in GitLab.

To enable the Bugzilla integration in a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Bugzilla**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Fill in the required fields:

   - **Project URL**: The URL to the project in Bugzilla.
     For example, for a product named "Fire Tanuki":
     `https://bugzilla.example.org/describecomponents.cgi?product=Fire+Tanuki`.
   - **Issue URL**: The URL to view an issue in the Bugzilla project.
     The URL must contain `:id`. GitLab replaces `:id` with the issue number (for example,
     `https://bugzilla.example.org/show_bug.cgi?id=:id`, which becomes
     `https://bugzilla.example.org/show_bug.cgi?id=123`).
   - **New issue URL**: The URL to create a new issue in the linked Bugzilla project.
     For example, for a project named "My Cool App":
     `https://bugzilla.example.org/enter_bug.cgi#h=dupes%7CMy+Cool+App`.

1. Optional. Select **Test settings**.
1. Select **Save changes**.

After you configure and enable Bugzilla, a link appears on the GitLab
project pages. This link takes you to the appropriate Bugzilla project.

You can also disable [GitLab internal issue tracking](../issues/_index.md) in this project.
For more information about the steps and consequences of disabling GitLab issues, see
Configure project [visibility](../../public_access.md#change-project-visibility), [features, and permissions](../settings/_index.md#configure-project-features-and-permissions).

## Reference Bugzilla issues in GitLab

You can reference issues in Bugzilla using:

- `#<ID>`, where `<ID>` is a number (for example, `#143`).
- `<PROJECT>-<ID>` (for example `API_32-143`) where:
  - `<PROJECT>` starts with a capital letter, followed by capital letters, numbers, or underscores.
  - `<ID>` is a number.

The `<PROJECT>` part is ignored in links, which always point to the address specified in **Issue URL**.

We suggest using the longer format (`<PROJECT>-<ID>`) if you have both internal and external issue
trackers enabled. If you use the shorter format, and an issue with the same ID exists in the
internal issue tracker, the internal issue is linked.

## Troubleshooting

For recent integration webhook deliveries, check the integration webhook logs.
