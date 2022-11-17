---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: howto
---

# Disabling GitLab CI/CD **(FREE)**

GitLab CI/CD is enabled by default on all new projects.
If you use an external CI/CD server like Jenkins or Drone CI, you can
disable GitLab CI/CD to avoid conflicts with the commits status
API.

You can disable GitLab CI/CD:

- [For each project](#disable-cicd-in-a-project).
- [For all new projects on an instance](../administration/cicd.md).

These changes do not apply to projects in an
[external integration](../user/project/integrations/index.md#available-integrations).

## Disable CI/CD in a project

When you disable GitLab CI/CD:

- The **CI/CD** item in the left sidebar is removed.
- The `/pipelines` and `/jobs` pages are no longer available.
- Existing jobs and pipelines are hidden, not removed.

To disable GitLab CI/CD in your project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. In the **Repository** section, turn off **CI/CD**.
1. Select **Save changes**.

## Enable CI/CD in a project

To enable GitLab CI/CD in your project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. In the **Repository** section, turn on **CI/CD**.
1. Select **Save changes**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
