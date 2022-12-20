---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Badges **(FREE)**

Badges are a unified way to present condensed pieces of information about your
projects. They consist of a small image and a URL that the image
points to. Examples for badges can be the [pipeline status](../../ci/pipelines/settings.md#pipeline-status-badge),
[test coverage](../../ci/pipelines/settings.md#test-coverage-report-badge), [latest release](../../ci/pipelines/settings.md#latest-release-badge), or ways to contact the
project maintainers.

![Badges on Project information page](img/project_overview_badges_v13_10.png)

## Project badges

Badges can be added to a project by Maintainers or Owners, and are visible on the project's overview page.
If you find that you have to add the same badges to several projects, you may want to add them at the [group level](#group-badges).

To add a new badge to a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Badges**.
1. Under "Link", enter the URL that the badges should point to and under
   "Badge image URL" the URL of the image that should be displayed.
1. Select **Add badge**.

After adding a badge to a project, you can see it in the list below the form.
You can edit the badge by selecting **Edit** (**{pencil}**) next to it or delete it by
selecting **Delete** (**{remove}**).

Badges associated with a group can only be edited or deleted on the
[group level](#group-badges).

### Example project badge: Pipeline Status

A common project badge presents the GitLab CI pipeline status.

To add this badge to a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Badges**.
1. Under **Name**, enter _Pipeline Status_.
1. Under **Link**, enter the following URL:
   `https://gitlab.com/%{project_path}/-/commits/%{default_branch}`
1. Under **Badge image URL**, enter the following URL:
   `https://gitlab.com/%{project_path}/badges/%{default_branch}/pipeline.svg`
1. Select **Add badge**.

## Group badges

By adding a badge to a group, you add and enforce a project-level badge
for all projects in the group. The group badge is visible on the **Overview**
page of any project that belongs to the group.

NOTE:
While these badges appear as project-level badges in the codebase, they
cannot be edited or deleted at the project level.

If you need individual badges for each project, either:

- Add the badge at the [project level](#project-badges).
- Use [placeholders](#placeholders).

To add a new badge to a group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Badges**.
1. Under "Link", enter the URL that the badges should point to and under
   "Badge image URL" the URL of the image that should be displayed.
1. Select **Add badge**.

After adding a badge to a group, you can see it in the list below the form.
You can edit the badge by selecting **Edit** (**{pencil}**) next to it or delete it by
selecting **Delete** (**{remove}**).

Badges directly associated with a project can be configured on the
[project level](#project-badges).

## Placeholders

Both the URL a badge points to and the image URL can contain placeholders
which are evaluated when displaying the badge. The following placeholders
are available:

- `%{project_path}`: Path of a project including the parent groups
- `%{project_title}`: Title of a project
- `%{project_name}`: Name of a project
- `%{project_id}`: Database ID associated with a project
- `%{default_branch}`: Default branch name configured for a project's repository
- `%{commit_sha}`: ID of the most recent commit to the default branch of a
  project's repository

NOTE:
Placeholders allow badges to expose otherwise-private information, such as the
default branch or commit SHA when the project is configured to have a private
repository. This is by design, as badges are intended to be used publicly. Avoid
using these placeholders if the information is sensitive.

## Use custom badge images

Use custom badge images in a project or a group if you want to use badges other than the default
ones.

Prerequisites:

- A valid URL that points directly to the desired image for the badge.
  If the image is located in a GitLab repository, use the raw link to the image.

Using placeholders, here is an example badge image URL referring to a raw image at the root of a repository:

```plaintext
https://gitlab.example.com/<project_path>/-/raw/<default_branch>/my-image.svg
```

To add a new badge to a group or project with a custom image:

1. On the top bar, select **Main menu** and find your group or project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Badges**.
1. Under **Name**, enter the name for the badge.
1. Under **Link**, enter the URL that the badge should point to.
1. Under **Badge image URL**, enter the URL that points directly to the custom image that should be
   displayed.
1. Select **Add badge**.

To learn how to use custom images generated via a pipeline, see our documentation on
[accessing the latest job artifacts by URL](../../ci/pipelines/job_artifacts.md#access-the-latest-job-artifacts).

## API

You can also configure badges via the GitLab API. As in the settings, there is
a distinction between endpoints for badges on the
[project level](../../api/project_badges.md) and [group level](../../api/group_badges.md).
