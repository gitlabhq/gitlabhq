---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# The scope of runners

Runners are available based on who you want to have access:

- [Shared runners](#shared-runners) are available to all groups and projects in a GitLab instance.
- [Group runners](#group-runners) are available to all projects and subgroups in a group.
- [Specific runners](#specific-runners) are associated with specific projects.
  Typically, specific runners are used for one project at a time.

## Shared runners

*Shared runners* are available to every project in a GitLab instance.

Use shared runners when you have multiple jobs with similar requirements. Rather than
having multiple runners idling for many projects, you can have a few runners that handle
multiple projects.

If you are using a self-managed instance of GitLab:

- Your administrator can install and register shared runners by
  going to your project's **Settings > CI/CD**, expanding the **Runners** section,
  and clicking **Show runner installation instructions**.
  These instructions are also available [in the documentation](https://docs.gitlab.com/runner/install/index.html).
- The administrator can also configure a maximum number of shared runner [pipeline minutes for
  each group](../../user/admin_area/settings/continuous_integration.md#shared-runners-pipeline-minutes-quota).

If you are using GitLab.com:

- You can select from a list of [shared runners that GitLab maintains](../../user/gitlab_com/index.md#shared-runners).
- The shared runners consume the [pipelines minutes](../../subscriptions/gitlab_com/index.md#ci-pipeline-minutes)
  included with your account.

### Enable shared runners

On GitLab.com, [shared runners](#shared-runners) are enabled in all projects by
default.

On self-managed instances of GitLab, an administrator must [install](https://docs.gitlab.com/runner/install/index.html)
and [register](https://docs.gitlab.com/runner/register/index.html) them.

You can also enable shared runners for individual projects.

To enable shared runners:

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. Select **Enable shared runners for this project**.

### Disable shared runners

You can disable shared runners for individual projects or for groups.
You must have the [Owner role](../../user/permissions.md#group-members-permissions) for the project
or group.

To disable shared runners for a project:

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. In the **Shared runners** area, select **Enable shared runners for this project** so the toggle is grayed-out.

Shared runners are automatically disabled for a project:

- If the shared runners setting for the parent group is disabled, and
- If overriding this setting is not permitted at the project level.

To disable shared runners for a group:

1. Go to the group's **Settings > CI/CD** and expand the **Runners** section.
1. In the **Shared runners** area, turn off the **Enable shared runners for this group** toggle.
1. Optionally, to allow shared runners to be enabled for individual projects or subgroups,
   click **Allow projects and subgroups to override the group setting**.

NOTE:
To re-enable the shared runners for a group, turn on the
**Enable shared runners for this group** toggle.
Then, an owner or maintainer must explicitly change this setting
for each project subgroup or project.

### How shared runners pick jobs

Shared runners process jobs by using a fair usage queue. This queue prevents
projects from creating hundreds of jobs and using all available
shared runner resources.

The fair usage queue algorithm assigns jobs based on the projects that have the
fewest number of jobs already running on shared runners.

**Example 1**

If these jobs are in the queue:

- Job 1 for Project 1
- Job 2 for Project 1
- Job 3 for Project 1
- Job 4 for Project 2
- Job 5 for Project 2
- Job 6 for Project 3

The fair usage algorithm assigns jobs in this order:

1. Job 1 is first, because it has the lowest job number from projects with no running jobs (that is, all projects).
1. Job 4 is next, because 4 is now the lowest job number from projects with no running jobs (Project 1 has a job running).
1. Job 6 is next, because 6 is now the lowest job number from projects with no running jobs (Projects 1 and 2 have jobs running).
1. Job 2 is next, because, of projects with the lowest number of jobs running (each has 1), it is the lowest job number.
1. Job 5 is next, because Project 1 now has 2 jobs running and Job 5 is the lowest remaining job number between Projects 2 and 3.
1. Finally is Job 3... because it's the only job left.

---

**Example 2**

If these jobs are in the queue:

- Job 1 for Project 1
- Job 2 for Project 1
- Job 3 for Project 1
- Job 4 for Project 2
- Job 5 for Project 2
- Job 6 for Project 3

The fair usage algorithm assigns jobs in this order:

1. Job 1 is chosen first, because it has the lowest job number from projects with no running jobs (that is, all projects).
1. We finish Job 1.
1. Job 2 is next, because, having finished Job 1, all projects have 0 jobs running again, and 2 is the lowest available job number.
1. Job 4 is next, because with Project 1 running a Job, 4 is the lowest number from projects running no jobs (Projects 2 and 3).
1. We finish Job 4.
1. Job 5 is next, because having finished Job 4, Project 2 has no jobs running again.
1. Job 6 is next, because Project 3 is the only project left with no running jobs.
1. Lastly we choose Job 3... because, again, it's the only job left.

## Group runners

Use *Group runners* when you want all projects in a group
to have access to a set of runners.

Group runners process jobs by using a first in, first out ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) queue.

### Create a group runner

You can create a group runner for your self-managed GitLab instance or for GitLab.com.
You must have the [Owner role](../../user/permissions.md#group-members-permissions) for the group.

To create a group runner:

1. [Install GitLab Runner](https://docs.gitlab.com/runner/install/).
1. Go to the group you want to make the runner work for.
1. Go to **Settings > CI/CD** and expand the **Runners** section.
1. Note the URL and token.
1. [Register the runner](https://docs.gitlab.com/runner/register/).

### View and manage group runners

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/37366/) in GitLab 13.2.

You can view and manage all runners for a group, its subgroups, and projects.
You can do this for your self-managed GitLab instance or for GitLab.com.
You must have the [Owner role](../../user/permissions.md#group-members-permissions) for the group.

1. Go to the group where you want to view the runners.
1. Go to **Settings > CI/CD** and expand the **Runners** section.
1. The following fields are displayed.

   | Attribute    | Description |
   | ------------ | ----------- |
   | Type         | Displays the runner type: `group` or `specific`, together with the optional states `locked` and `paused` |
   | Runner token | Token used to identify the runner, and that the runner uses to communicate with the GitLab instance |
   | Description  | Description given to the runner when it was created |
   | Version      | GitLab Runner version |
   | IP address   | IP address of the host on which the runner is registered |
   | Projects     | The count of projects to which the runner is assigned |
   | Jobs         | Total of jobs run by the runner |
   | Tags         | Tags associated with the runner |
   | Last contact | Timestamp indicating when the GitLab instance last contacted the runner |

From this page, you can edit, pause, and remove runners from the group, its subgroups, and projects.

### Pause or remove a group runner

You can pause or remove a group runner for your self-managed GitLab instance or for GitLab.com.
You must have the [Owner role](../../user/permissions.md#group-members-permissions) for the group.

1. Go to the group you want to remove or pause the runner for.
1. Go to **Settings > CI/CD** and expand the **Runners** section.
1. Click **Pause** or **Remove runner**.
   - If you pause a group runner that is used by multiple projects, the runner pauses for all projects.
   - From the group view, you cannot remove a runner that is assigned to more than one project.
     You must remove it from each project first.
1. On the confirmation dialog, click **OK**.

## Specific runners

Use *Specific runners* when you want to use runners for specific projects. For example,
when you have:

- Jobs with specific requirements, like a deploy job that requires credentials.
- Projects with a lot of CI activity that can benefit from being separate from other runners.

You can set up a specific runner to be used by multiple projects. Specific runners
must be enabled for each project explicitly.

Specific runners process jobs by using a first in, first out ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) queue.

NOTE:
Specific runners do not get shared with forked projects automatically.
A fork *does* copy the CI/CD settings of the cloned repository.

### Create a specific runner

You can create a specific runner for your self-managed GitLab instance or for GitLab.com.
You must have the [Owner role](../../user/permissions.md#project-members-permissions) for the project.

To create a specific runner:

1. [Install runner](https://docs.gitlab.com/runner/install/).
1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. Note the URL and token.
1. [Register the runner](https://docs.gitlab.com/runner/register/).

### Enable a specific runner for a specific project

A specific runner is available in the project it was created for. An administrator can
enable a specific runner to apply to additional projects.

- You must have the [Owner role](../../user/permissions.md#group-members-permissions) for the
  project.
- The specific runner must not be [locked](#prevent-a-specific-runner-from-being-enabled-for-other-projects).

To enable or disable a specific runner for a project:

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. Click **Enable for this project** or **Disable for this project**.

### Prevent a specific runner from being enabled for other projects

You can configure a specific runner so it is "locked" and cannot be enabled for other projects.
This setting can be enabled when you first [register a runner](https://docs.gitlab.com/runner/register/),
but can also be changed later.

To lock or unlock a runner:

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. Find the runner you want to lock or unlock. Make sure it's enabled.
1. Click the pencil button.
1. Check the **Lock to current projects** option.
1. Click **Save changes**.
