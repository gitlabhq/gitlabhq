---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Bugzilla service **(FREE)**

[Bugzilla](https://www.bugzilla.org/) is a web-based general-purpose bug tracking system and testing
tool.

You can configure Bugzilla as an
[external issue tracker](../../../integration/external-issue-tracker.md) in GitLab.

To enable the Bugzilla integration in a project:

1. Go to the [Integrations page](overview.md#accessing-integrations).
1. Select **Bugzilla**.
1. Select the checkbox under **Enable integration**.
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

1. Select **Save changes** or optionally select **Test settings**.

After you configure and enable Bugzilla, a link appears on the GitLab
project pages. This link takes you to the appropriate Bugzilla project.

You can also disable [GitLab internal issue tracking](../issues/index.md) in this project.
Learn more about the steps and consequences of disabling GitLab issues in
[Sharing and permissions](../settings/index.md#sharing-and-permissions).

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

To see recent service hook deliveries, check [service hook logs](overview.md#troubleshooting-integrations).
