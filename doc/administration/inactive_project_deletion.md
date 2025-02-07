---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Inactive project deletion
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) in GitLab 15.0 [with a flag](feature_flags.md) named `inactive_projects_deletion`. Disabled by default.
> - [Feature flag `inactive_projects_deletion`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96803) removed in GitLab 15.4.
> - Configuration through GitLab UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85575) in GitLab 15.1.

Administrators of large GitLab instances can find that over time, projects become inactive and are no longer used.
These projects take up unnecessary disk space.

With inactive project deletion, you can identify these projects, warn the maintainers ahead of time, and then delete the
projects if they remain inactive. When an inactive project is deleted, the action generates an audit event that it was
performed by the @GitLab-Admin-Bot.

For the default setting on GitLab.com, see the [GitLab.com settings page](../user/gitlab_com/_index.md#inactive-project-deletion).

## Configure inactive project deletion

To configure deletion of inactive projects:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Repository**.
1. Expand **Repository maintenance**.
1. In the **Inactive project deletion** section, select **Delete inactive projects**.
1. Configure the settings.
   - The warning email is sent to users who have the Owner and Maintainer role for the inactive project.
   - The email duration must be less than the **Delete project after** duration.
1. Select **Save changes**.

Inactive projects that meet the criteria are scheduled for deletion and a warning email is sent. If the
projects remain inactive, they are deleted after the specified duration. These projects are deleted even if
[the project is archived](../user/project/working_with_projects.md#archive-a-project).

### Configuration example

#### Example 1

If you use these settings:

- **Delete inactive projects** enabled.
- **Delete inactive projects that exceed** set to `50`.
- **Delete project after** set to `12`.
- **Send warning email** set to `6`.

If a project is less than 50 MB, the project is not considered inactive.

If a project is more than 50 MB and it is inactive for:

- More than 6 months: A deletion warning email is sent. This mail includes the date that the project will be deleted.
- More than 12 months: The project is scheduled for deletion.

#### Example 2

If you use these settings:

- **Delete inactive projects** enabled.
- **Delete inactive projects that exceed** set to `0`.
- **Delete project after** set to `12`.
- **Send warning email** set to `11`.

If a project exists that has already been inactive for more than 12 months when you configure these settings:

- A deletion warning email is sent immediately. This email includes the date that the project will be deleted.
- The project is scheduled for deletion 1 month (12 months - 11 months) after warning email.

## Determine when a project was last active

You can view a project's activities and determine when the project was last active in the following ways:

- Go to the [activity page](../user/project/working_with_projects.md#view-project-activity) for the project and view
  the date of the latest event.
- View the `last_activity_at` attribute for the project using the [Projects API](../api/projects.md).
- List the visible events for the project using the [Events API](../api/events.md#list-a-projects-visible-events).
  View the `created_at` attribute of the latest event.
