---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Redmine service **(FREE)**

Use [Redmine](https://www.redmine.org/) as the issue tracker.

To enable the Redmine integration in a project:

1. Go to the [Integrations page](overview.md#accessing-integrations).
1. Select **Redmine**.
1. Select the checkbox under **Enable integration**.
1. Fill in the required fields:

   - **Project URL**: The URL to the Redmine project to link to this GitLab project.
   - **Issue URL**: The URL to the Redmine project issue to link to this GitLab project.
     The URL must contain `:id`. GitLab replaces this ID with the issue number.
   - **New issue URL**: The URL to use to create a new issue in the Redmine project linked to
     this GitLab project.
     <!-- The line below was originally added in January 2018: https://gitlab.com/gitlab-org/gitlab/-/commit/778b231f3a5dd42ebe195d4719a26bf675093350 -->
     **This URL is not used and removal is planned in a future release.**
     For more information, see [issue 327503](https://gitlab.com/gitlab-org/gitlab/-/issues/327503).

1. Select **Save changes** or optionally select **Test settings**.

After you have configured and enabled Redmine, you see the Redmine link on the GitLab project pages,
which takes you to your Redmine project.

For example, this is a configuration for a project named `gitlab-ci`:

- Project URL: `https://redmine.example.com/projects/gitlab-ci`
- Issue URL: `https://redmine.example.com/issues/:id`
- New issue URL: `https://redmine.example.com/projects/gitlab-ci/issues/new`

You can also disable [GitLab internal issue tracking](../issues/index.md) in this project.
Learn more about the steps and consequences of disabling GitLab issues in
[Sharing and permissions](../settings/index.md#sharing-and-permissions).

## Reference Redmine issues in GitLab

You can reference your Redmine issues using:

- `#<ID>`, where `<ID>` is a number (example `#143`).
- `<PROJECT>-<ID>`, for example `API_32-143`, where:
  - `<PROJECT>` starts with a capital letter, followed by capital letters, numbers, or underscores.
  - `<ID>` is a number.

In links, the `<PROJECT>` part is ignored, and they always point to the address specified in **Issue URL**.

We suggest using the longer format (`<PROJECT>-<ID>`) if you have both internal and external issue
trackers enabled. If you use the shorter format, and an issue with the same ID exists in the
internal issue tracker, the internal issue is linked.
