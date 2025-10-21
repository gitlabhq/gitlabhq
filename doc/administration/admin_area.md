---
stage: None - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
group: Unassigned - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Manage your GitLab instance and configure features in the UI.
title: GitLab Admin area
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The **Admin** area provides a web UI to manage and configure features of a
GitLab Self-Managed instance. If you are an administrator, to access the **Admin** area:

- In GitLab 17.3 and later: on the left sidebar, at the bottom, select **Admin**.
- In GitLab 16.7 and later: on the left sidebar, at the bottom, select **Admin area**.
- In GitLab 16.1 and later: on the left sidebar, select **Search or go to**, then select **Admin**.
- In GitLab 16.0 and earlier: on the top bar, select **Main menu** > **Admin**.

If the GitLab instance uses Admin Mode, you must
[enable Admin Mode for your session](settings/sign_in_restrictions.md#turn-on-admin-mode-for-your-session) before
**Admin** is visible.

{{< alert type="note" >}}

Only administrators on GitLab Self-Managed or GitLab Dedicated can access the **Admin** area.
On GitLab.com, the **Admin** area feature is not available.

{{< /alert >}}

## Administering projects

{{< history >}}

- New look [introduced](https://gitlab.com/groups/gitlab-org/-/epics/17782) in GitLab 18.2 [with a flag](feature_flags/_index.md) named `admin_projects_vue`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/549452) in GitLab 18.3. Feature flag `admin_projects_vue` removed.

{{< /history >}}

To administer all projects in the GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Projects**. The page shows each project's:

   - Name
   - Description
   - Visibility level
   - Role
   - Topics
   - Status
   - Storage size
   - Number of stars
   - Number of forks
   - Number of merge requests
   - Number of issues

1. Optional. Select a tab:

   - **Active** shows all active projects.
   - **Inactive** shows projects that are archived or pending deletion.

1. Optional. Combine filters to find your desired projects. Filter by:

   - Name. You must enter at least three characters.
   - Visibility, either public, internal, or private.
   - Programming language.
   - Group or user namespace.
   - Projects where you have the Owner role.

1. Optional. To change the sort order, select the sort dropdown list and choose the desired order.
   The available sort options are:

   - Name
   - Created date
   - Updated date
   - Stars
   - Storage size

### Edit a project

To edit a project's name or description from the **Admin** area's Projects page:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Projects**.
1. Find the project you want to edit and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Edit**.
1. Edit the **Project name** or **Project description**.
1. Select **Save Changes**.

### Delete a project

To delete a project:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Projects**.
1. Find the project you want to edit and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Delete**.
1. On the confirmation dialog, select **Yes, delete project**.

## Administering users

{{< history >}}

- Filtering users [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) in GitLab 17.0.

{{< /history >}}

The **Admin** area's Users page shows this information for each user:

- Username
- Email address
- Project membership count
- Group membership count
- Date of account creation
- Date of last activity

To administer all users from the **Admin** area's Users page:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Users**.
1. Optional. To change the sort order, which defaults to user name:

   1. Select the sort dropdown list.
   1. Select the desired order.

1. Optional. Use the user search box to search and filter users by:

   - User **access level**.
   - Whether **two-factor authentication** is enabled or disabled.
   - User **state**.
   - Whether the user **type** is [placeholder](../user/project/import/_index.md#placeholder-users).

1. Optional. In the user search field, enter text, then press <kbd>Enter</kbd>. This case-insensitive
   text search applies partial matching to name, username, and email.

To edit a user, find the user's row and select **Edit**.

### Delete a user

To delete the user, or delete the user and their contributions, from the **Admin** area's Users page:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Users**.
1. Find the user you want to delete. In the row, select **User administration**
   ({{< icon name="ellipsis_v">}}), then select the desired option.

### User impersonation

An administrator can impersonate any other user, including other administrators.
This enables you to see what the user sees in GitLab, and take actions on behalf of the user.

To impersonate a user:

- Through the UI:
  1. On the left sidebar, at the bottom, select **Admin**.
  1. On the left sidebar, select **Overview** > **Users**.
  1. From the list of users, select a user.
  1. On the upper right, select **Impersonate**.
  1. To stop impersonating, on the left sidebar at the top, select **Stop impersonating** ({{< icon name="incognito">}}).
- With the API, using [impersonation tokens](../api/rest/authentication.md#impersonation-tokens).

All impersonation activities are [captured with audit events](compliance/audit_event_reports.md#user-impersonation).
By default, impersonation is enabled. GitLab can be configured to
[disable impersonation](../api/rest/authentication.md#disable-impersonation).

### User identities

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- Viewing a user's SCIM identity [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/294608) in GitLab 15.3.

{{< /history >}}

When using authentication providers, administrators can see the identities for a user. This page
shows the user's identities, including SCIM identities. Use this information to troubleshoot
SCIM-related issues and confirm the identities being used for an account.

To do this:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Users**.
1. From the list of users, select a user.
1. Select **Identities**.

### User permission export

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When you export user permissions, the exported information shows the direct membership users have
in groups and projects. It includes this data, and is limited to the first 100,000 users:

- Username
- Email
- Type
- Path
- Access level ([Project](../user/permissions.md#project-members-permissions) and
  [Group](../user/permissions.md#group-members-permissions))
- Date of last activity. For a list of activities that populate this column, see the
  [Users API documentation](../api/users.md#list-a-users-activity).

To export user permissions for all active users in your GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Users**.
1. On the upper right, select **Export permissions as CSV** ({{< icon name="export" >}}).

### Users statistics

The **Users statistics** page provides an overview of user accounts by role. These statistics are
calculated daily. User changes made after the last update are not reflected. These totals are also included:

- Billable users
- Blocked users
- Total users

GitLab billing is based on the number of [billable users](../subscriptions/manage_users_and_seats.md#billable-users).

### Add email to user

To add email addresses to user accounts manually:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Users**.
1. Locate the user and select them.
1. Select **Edit**.
1. In **Email**, enter the new email address. This adds the new email address to the
   user and sets the previous email address to be a secondary.
1. Select **Save changes**.

## User cohorts

The [Cohorts](user_cohorts.md) tab displays the monthly cohorts of new users and their activities over time.

## Prevent a user from creating top-level groups

Administrators can prevent specific users from creating top-level groups. These users can still
create subgroups and collaborate in existing organizational structures.

To prevent a user from creating top-level groups:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Users**.
1. Locate the user and select them.
1. Select **Edit**.
1. Clear the **Can create top-level group** checkbox.
1. Select **Save changes**.

After you turn off this setting:

- The user cannot create top-level groups.
- The user can create subgroups in groups where they have at least the Maintainer role,
  depending on the [subgroup creation permissions](../user/group/subgroups/_index.md#change-who-can-create-subgroups)
  for the group.

## Administering groups

{{< history >}}

- New look [introduced](https://gitlab.com/groups/gitlab-org/-/epics/17783) in GitLab 18.2 [with a flag](feature_flags/_index.md) named `admin_groups_vue`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/553229) in GitLab 18.5.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

To administer all groups in the GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Groups**. The page shows each group's:

   - Name
   - Description
   - Visibility level
   - Role
   - Status
   - Storage size
   - Number of subgroups
   - Number of projects
   - Member count

1. Optional. Select a tab:

   - **Active** shows all active groups.
   - **Inactive** shows groups that are pending deletion.

1. Optional. To change the sort order, select the sort dropdown list and choose the desired order.
   The available sort options are:

   - Name
   - Created date
   - Updated date
   - [Storage size](../user/storage_usage_quotas.md)

1. Optional. To filter groups by name, in the search bar, enter at least three characters.
1. Optional. To [create a new group](../user/group/_index.md#create-a-group) select **New group**.

### Edit a group

To edit a group's name or description from the **Admin** area's Groups page:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Groups**.
1. Find the group you want to edit and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Edit**.
1. Edit the **Group name** or **Group description**.
1. Select **Save Changes**.

### Delete a group

To delete a group:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Groups**.
1. Find the group you want to edit and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Delete**.
1. On the confirmation dialog, select **Confirm**.

## Administering topics

{{< history >}}

- Merging topics [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366884) in GitLab 15.5.

{{< /history >}}

Categorize and find similar projects with [topics](../user/project/project_topics.md).

### View all topics

To view all topics in the GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Topics**.

For each topic, the page displays its name and the number of projects labeled with the topic.

### Search for topics

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Topics**.
1. In the search box, enter your search criteria.
   The topic search is case-insensitive and applies partial matching.

### Create a topic

To create a topic:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Topics**.
1. Select **New topic**.
1. Enter the **Topic slug (name)** and **Topic title**.
1. Optional. Enter a **Description** and add a **Topic avatar**.
1. Select **Save changes**.

The created topics are displayed on the **Explore topics** page.

The assigned topics are visible only to everyone with access to the project,
but everyone can see which topics exist on the GitLab instance.
Do not include sensitive information in the name of a topic.

### Edit a topic

You can edit a topic's name, title, description, and avatar at any time.
To edit a topic:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Topics**.
1. Select **Edit** in that topic's row.
1. Edit the topic slug (name), title, description, or avatar.
1. Select **Save changes**.

### Remove a topic

If you no longer need a topic, you can permanently remove it.
To remove a topic:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Topics**.
1. To remove a topic, select **Remove** in that topic's row.

### Merge topics

You can move all projects assigned to a topic to another topic.
The source topic is then permanently deleted.
After a merged topic is deleted, you cannot restore it.

To merge topics:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Topics**.
1. Select **Merge topics**.
1. From the **Source topic** dropdown list, select the topic you want to merge and remove.
1. From the **Target topic** dropdown list, select the topic you want to merge the source topic into.
1. Select **Merge**.

## Administering Gitaly servers

You can list all Gitaly servers in the GitLab instance from the **Admin** area's **Gitaly servers**
page. For more details, see [Gitaly](gitaly/_index.md).

To access the **Gitaly servers** page:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Gitaly servers**.

The page includes this information about each Gitaly server:

| Field          | Description |
|----------------|-------------|
| Storage        | Repository storage |
| Address        | Network address on which the Gitaly server is listening |
| Server version | Gitaly version |
| Git version    | Version of Git installed on the Gitaly server |
| Up to date     | Indicates if the Gitaly server version is the latest version available. A green dot indicates the server is up to date. |

## Administering organizations

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419540) in GitLab 16.10 [with a flag](feature_flags/_index.md) named `ui_for_organizations`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator
can [enable the feature flag](feature_flags/_index.md) named `ui_for_organizations`.
On GitLab.com and GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

{{< /alert >}}

The Organizations page in the **Admin** area lists all projects by default, in reverse order of when
they were last updated. Each project shows:

- Name
- Namespace
- Description
- Size, updated every 15 minutes at most

To administer all organizations in the GitLab instance from this page:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Organizations**.

## CI/CD section

### Administering runners

{{< history >}}

- [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/340859) from **Overview** > **Runners** to **CI/CD** > **Runners** in GitLab 15.8.

{{< /history >}}

To administer all runners in the GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **CI/CD** > **Runners**.

This information is shown for each runner:

| Attribute    | Description |
|--------------|-------------|
| Status       | The status of the runner. In [GitLab 15.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/22224), for the Ultimate tier, the upgrade status is available. |
| Runner details | Information about the runner, including partial token and details about the computer the runner was registered from. |
| Version      | GitLab Runner version. |
| Jobs         | Total number of jobs run by the runner. |
| Tags         | Tags associated with the runner. |
| Last contact | Timestamp indicating when the runner last contacted the GitLab instance. |

You can also edit, pause, or remove each runner.

For more information, see [GitLab Runner](https://docs.gitlab.com/runner/).

#### Search and filter runners

To search runners' descriptions:

1. In the **Search or filter results** text box, enter the description of the runner you want to
   find.
1. Press <kbd>Enter</kbd>.

To filter runners by status, type, and tag:

1. Select a tab or the **Search or filter results** text box.
1. Select any **Type**, or filter by **Status** or **Tags**.
1. Select or enter your search criteria.

![Attributes of a runner filtered by status.](img/index_runners_search_or_filter_v14_5.png)

#### Bulk delete runners

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/370241) in GitLab 15.4.
- [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/353981) in GitLab 15.5.

{{< /history >}}

To delete multiple runners at the same time:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Runners**.
1. To the left of the runner you want to delete, select the checkbox.
   To select all runners on the page, select the checkbox above
   the list.
1. Select **Delete selected**.

### Administering jobs

{{< history >}}

- [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/386311) from **Overview** > **Jobs** to **CI/CD** > **Jobs** in GitLab 15.8.

{{< /history >}}

To administer all jobs in the GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **CI/CD** > **Jobs**. All jobs are listed, in descending order of job ID.
1. Select the **All** tab to list all jobs. Select the **Pending**, **Running**, or **Finished**
   tab to list only jobs of that status.

For each job, the following details are listed:

| Field    | Description |
|----------|-------------|
| Status   | Job status. One of **passed**, **skipped**, or **failed**.              |
| Job      | Includes links to the job, branch, and the commit that started the job. |
| Pipeline | Includes a link to the specific pipeline.                               |
| Project  | Name of the project, and organization, to which the job belongs.        |
| Runner   | Name of the CI runner assigned to execute the job.                      |
| Stage    | Stage that the job is declared in a `.gitlab-ci.yml` file.              |
| Name     | Name of the job specified in a `.gitlab-ci.yml` file.                   |
| Timing   | Duration of the job, and how long ago the job completed.                |
| Coverage | Percentage of tests coverage.                                           |

## Monitoring section

The following topics document the **Monitoring** section of the **Admin** area.

### System information

{{< history >}}

- Support for relative time [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/341248) in GitLab 15.2. "Uptime" statistic was renamed to "System started".

{{< /history >}}

The **System information** page provides the following statistics:

| Field          | Description                                       |
|:---------------|:--------------------------------------------------|
| CPU            | Number of CPU cores available                     |
| Memory Usage   | Memory in use, and total memory available         |
| Disk Usage     | Disk space in use, and total disk space available |
| System started | When the system hosting GitLab was started. In GitLab 15.1 and earlier, this was an uptime statistic. |

These statistics are updated only when you go to the **System information** page, or you refresh the
page in your browser.

### Background jobs

The **Background jobs** page displays the Sidekiq dashboard. Sidekiq is used by GitLab to
perform background processes.

The Sidekiq dashboard contains:

- A tab for each [job's lifecycle status](https://github.com/sidekiq/sidekiq/wiki/Job-Lifecycle).
- A breakdown of background job statistics.
- A live graph of **Processed** and **Failed** jobs, with a selectable polling interval.
- An historical graph of **Processed** and **Failed** jobs, with a selectable time span.
- Redis statistics, including:
  - Version number
  - Uptime, measured in days
  - Number of connections
  - Current memory usage, measured in MB
  - Peak memory usage, measured in MB

### Database diagnostics

{{< history >}}

- Collation health check [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/555916) in GitLab 18.3.
- Schema health check [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199796) in GitLab 18.3 with missing indexes, tables, foreign keys, and sequences checks.
- Wrong sequence owners check [added to schema health check](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197521) in GitLab 18.4.

{{< /history >}}

The database diagnostics page consists of a number of checks that
attempt to flag common problems with the database:

- Index corruption caused by [change in PostgreSQL collations](https://gitlab.com/groups/gitlab-org/-/epics/8573)
- [Schema discrepancies](https://gitlab.com/groups/gitlab-org/-/epics/3928)

To run each check, select the run button for the check. Selecting the run button
schedules a background job that will report information from the check to the page.

#### Collation health check

The collation health check attempts to detect PostgreSQL issues that
result in corrupted indexes. This commonly happens if the previous
operating system running PostgreSQL used a version of `glibc` earlier than
version 2.28. For more information, see the documentation about
[upgrading operating systems for PostgreSQL](postgresql/upgrading_os.md).

Any issues are listed in a **Corrupted Indexes** section. If you have issues, you can
[repair corrupted indexes](raketasks/maintenance.md#repair-corrupted-database-indexes).

The collation health check also attempts to flag duplicates on commonly-affected tables:

- `ci_refs`
- `ci_resource_groups`
- `environments`
- `merge_request_diff_commit_users`
- `sbom_components`
- `tags`
- `topics`

For more information, see [issue 505982](https://gitlab.com/gitlab-org/gitlab/-/issues/505982).

The dashboard lists the identical information shown in the
[`gitlab:db:collation_checker` Rake task](raketasks/maintenance.md#detect-postgresql-collation-version-mismatches).

#### Schema health check

The schema health check compares the state of the database against the target schema and lists detected
discrepancies. No automated schema repair tool is available.

If you notice any false positives or have any questions about the results of the check, see the
[feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/567561).

### Logs

The contents of these log files can help troubleshoot a problem. The content of each log file is
listed in chronological order. To minimize performance issues, a maximum 2000 lines of each log file
are shown.

| Log file                | Contents |
|:------------------------|:---------|
| `application_json.log`  | GitLab user activity |
| `git_json.log`          | Failed GitLab interaction with Git repositories |
| `production.log`        | Requests received from Puma, and the actions taken to serve those requests |
| `sidekiq.log`           | Background jobs |
| `repocheck.log`         | Repository activity |
| `integrations_json.log` | Activity between GitLab and integrated systems |
| `kubernetes.log`        | Kubernetes activity |

For details of these log files and their contents, see [Log system](logs/_index.md).

The **Log** view has been removed from the **Admin** area dashboard to prevent confusion for administrators
of multi-node systems. This view presents partial information for multi-node setups. For multi-node
systems, ingest the logs into services like Elasticsearch and Splunk.

### Audit events

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The **Audit events** page lists changes made to the GitLab server. Use this information to
control, analyze, and track every change.

### Statistics

The **Instance overview** section of the Dashboard lists the current statistics of the GitLab instance.
Retrieve this information with the
[Application statistics API](../api/statistics.md#get-details-on-current-application-statistics).

These statistics show exact counts for values less than 10,000. For values of 10,000 and higher,
these statistics show approximate data
when [`TablesampleCountStrategy`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/tablesample_count_strategy.rb?ref_type=heads#L16) and
[`ReltuplesCountStrategy`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/reltuples_count_strategy.rb?ref_type=heads)
strategies are used for calculations.
