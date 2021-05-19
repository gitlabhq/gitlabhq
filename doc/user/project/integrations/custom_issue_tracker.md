---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Custom issue tracker service **(FREE)**

Use a custom issue tracker that is not in the integration list.

To enable a custom issue tracker in a project:

1. Go to the [Integrations page](overview.md#accessing-integrations).
1. Select **Custom issue tracker**.
1. Select the checkbox under **Enable integration**.
1. Fill in the required fields:

   - **Project URL**: The URL to view all the issues in the custom issue tracker.
   - **Issue URL**: The URL to view an issue in the custom issue tracker. The URL must contain `:id`.
   GitLab replaces `:id` with the issue number (for example,
   `https://customissuetracker.com/project-name/:id`, which becomes `https://customissuetracker.com/project-name/123`).
   - **New issue URL**:
     <!-- The line below was originally added in January 2018: https://gitlab.com/gitlab-org/gitlab/-/commit/778b231f3a5dd42ebe195d4719a26bf675093350 -->
     **This URL is not used and removal is planned in a future release.**
     Enter any URL here.
     For more information, see [issue 327503](https://gitlab.com/gitlab-org/gitlab/-/issues/327503).

1. Select **Save changes** or optionally select **Test settings**.

After you configure and enable the custom issue tracker service, a link appears on the GitLab
project pages. This link takes you to the custom issue tracker.

## Reference issues in a custom issue tracker

You can reference issues in a custom issue tracker using:

- `#<ID>`, where `<ID>` is a number (for example, `#143`).
- `<PROJECT>-<ID>` (for example `API_32-143`) where:
  - `<PROJECT>` starts with a capital letter, followed by capital letters, numbers, or underscores.
  - `<ID>` is a number.

The `<PROJECT>` part is ignored in links, which always point to the address specified in **Issue URL**.

We suggest using the longer format (`<PROJECT>-<ID>`) if you have both internal and external issue
trackers enabled. If you use the shorter format, and an issue with the same ID exists in the
internal issue tracker, the internal issue is linked.
