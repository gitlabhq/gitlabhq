---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference
---

# Configuring runners in GitLab
<!-- This topic contains several commented-out sections that were accidentally added in 13.2.-->
<!-- The commented-out sections will be added back in a future release.-->

In GitLab CI/CD, runners run the code defined in [`.gitlab-ci.yml`](../yaml/README.md).
A runner is a lightweight, highly-scalable agent that picks up a CI job through
the coordinator API of GitLab CI/CD, runs the job, and sends the result back to the GitLab instance.

Runners are created by an administrator and are visible in the GitLab UI.
Runners can be specific to certain projects or available to all projects.

This documentation is focused on using runners in GitLab.
If you need to install and configure GitLab Runner, see
[the GitLab Runner documentation](https://docs.gitlab.com/runner/).

## Types of runners

In the GitLab UI there are three types of runners, based on who you want to have access:

- [Shared runners](#shared-runners) are available to all groups and projects in a GitLab instance.
- [Group runners](#group-runners) are available to all projects and subgroups in a group.
- [Specific runners](#specific-runners) are associated with specific projects.
  Typically, specific runners are used for one project at a time.

### Shared runners

*Shared runners* are available to every project in a GitLab instance.

Use shared runners when you have multiple jobs with similar requirements. Rather than
having multiple runners idling for many projects, you can have a few runners that handle
multiple projects.

If you are using a self-managed instance of GitLab:

- Your administrator can install and register shared runners by [following the documentation](https://docs.gitlab.com/runner/install/index.html).
  <!-- going to your project's
  <!-- **Settings > CI / CD**, expanding the **Runners** section, and clicking **Show runner installation instructions**.-->
  <!-- These instructions are also available [in the documentation](https://docs.gitlab.com/runner/install/index.html).-->
- The administrator can also configure a maximum number of shared runner [pipeline minutes for
  each group](../../user/admin_area/settings/continuous_integration.md#shared-runners-pipeline-minutes-quota).

If you are using GitLab.com:

- You can select from a list of [shared runners that GitLab maintains](../../user/gitlab_com/index.md#shared-runners).
- The shared runners consume the [pipelines minutes](../../subscriptions/gitlab_com/index.md#ci-pipeline-minutes)
  included with your account.

#### How shared runners pick jobs

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

1. Job 1 is chosen first, because it has the lowest job number from projects with no running jobs (that is, all projects).
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

#### Enable shared runners

On GitLab.com, [shared runners](#shared-runners) are enabled in all projects by
default.

On self-managed instances of GitLab, an administrator must [install](https://docs.gitlab.com/runner/install/index.html)
and [register](https://docs.gitlab.com/runner/register/index.html) them.

You can also enable shared runners for individual projects.

To enable shared runners:

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. Click **Allow shared runners**.

#### Disable shared runners

You can disable shared runners for individual projects or for groups.
You must have Owner permissions for the project or group.

To disable shared runners for a project:

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. In the **Shared runners** area, click **Disable shared runners**.

To disable shared runners for a group:

1. Go to the group's **Settings > CI/CD** and expand the **Runners** section.
1. In the **Shared runners** area, click **Enable shared runners for this group**.
1. Optionally, to allow shared runners to be enabled for individual projects or subgroups,
   click **Allow projects and subgroups to override the group setting**.

### Group runners

Use *Group runners* when you want all projects in a group
to have access to a set of runners.

Group runners process jobs by using a first in, first out ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) queue.

#### Create a group runner

You can create a group runner for your self-managed GitLab instance or for GitLab.com.
You must have [Owner permissions](../../user/permissions.md#group-members-permissions) for the group.

To create a group runner:

1. [Install GitLab Runner](https://docs.gitlab.com/runner/install/).
1. Go to the group you want to make the runner work for.
1. Go to **Settings > CI/CD** and expand the **Runners** section.
1. Note the URL and token.
1. [Register the runner](https://docs.gitlab.com/runner/register/).

#### View and manage group runners

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/37366/) in GitLab 13.2.

You can view and manage all runners for a group, its subgroups, and projects.
You can do this for your self-managed GitLab instance or for GitLab.com.
You must have [Owner permissions](../../user/permissions.md#group-members-permissions) for the group.

1. Go to the group where you want to view the runners.
1. Go to **Settings > CI/CD** and expand the **Runners** section.
1. The following fields are displayed.

   | Attribute    | Description |
   | ------------ | ----------- |
   | Type         | One or more of the following states: shared, group, specific, locked, or paused |
   | Runner token | Token used to identify the runner, and that the runner uses to communicate with the GitLab instance |
   | Description  | Description given to the runner when it was created |
   | Version      | GitLab Runner version |
   | IP address   | IP address of the host on which the runner is registered |
   | Projects     | The count of projects to which the runner is assigned |
   | Jobs         | Total of jobs run by the runner |
   | Tags         | Tags associated with the runner |
   | Last contact | Timestamp indicating when the GitLab instance last contacted the runner |

From this page, you can edit, pause, and remove runners from the group, its subgroups, and projects.

#### Pause or remove a group runner

You can pause or remove a group runner for your self-managed GitLab instance or for GitLab.com.
You must have [Owner permissions](../../user/permissions.md#group-members-permissions) for the group.

1. Go to the group you want to remove or pause the runner for.
1. Go to **Settings > CI/CD** and expand the **Runners** section.
1. Click **Pause** or **Remove runner**.
   - If you pause a group runner that is used by multiple projects, the runner pauses for all projects.
   - From the group view, you cannot remove a runner that is assigned to more than one project.
     You must remove it from each project first.
1. On the confirmation dialog, click **OK**.

### Specific runners

Use *Specific runners* when you want to use runners for specific projects. For example,
when you have:

- Jobs with specific requirements, like a deploy job that requires credentials.
- Projects with a lot of CI activity that can benefit from being separate from other runners.

You can set up a specific runner to be used by multiple projects. Specific runners
must be enabled for each project explicitly.

Specific runners process jobs by using a first in, first out ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) queue.

NOTE: **Note:**
Specific runners do not get shared with forked projects automatically.
A fork *does* copy the CI / CD settings of the cloned repository.

#### Create a specific runner

You can create a specific runner for your self-managed GitLab instance or for GitLab.com.
You must have [Owner permissions](../../user/permissions.md#project-members-permissions) for the project.

To create a specific runner:

1. [Install runner](https://docs.gitlab.com/runner/install/).
1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. Note the URL and token.
1. [Register the runner](https://docs.gitlab.com/runner/register/).

#### Enable a specific runner for a specific project

A specific runner is available in the project it was created for. An administrator can
enable a specific runner to apply to additional projects.

- You must have Owner permissions for the project.
- The specific runner must not be [locked](#prevent-a-specific-runner-from-being-enabled-for-other-projects).

To enable or disable a specific runner for a project:

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. Click **Enable for this project** or **Disable for this project**.

#### Prevent a specific runner from being enabled for other projects

You can configure a specific runner so it is "locked" and cannot be enabled for other projects.
This setting can be enabled when you first [register a runner](https://docs.gitlab.com/runner/register/),
but can also be changed later.

To lock or unlock a runner:

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. Find the runner you want to lock or unlock. Make sure it's enabled.
1. Click the pencil button.
1. Check the **Lock to current projects** option.
1. Click **Save changes**.

## Manually clear the runner cache

Read [clearing the cache](../caching/index.md#clearing-the-cache).

## Set maximum job timeout for a runner

For each runner, you can specify a *maximum job timeout*. This timeout,
if smaller than the [project defined timeout](../pipelines/settings.md#timeout), takes precedence.

This feature can be used to prevent your shared runner from being overwhelmed
by a project that has jobs with a long timeout (for example, one week).

When not configured, runners do not override the project timeout.

How this feature works:

**Example 1 - Runner timeout bigger than project timeout**

1. You set the _maximum job timeout_ for a runner to 24 hours
1. You set the _CI/CD Timeout_ for a project to **2 hours**
1. You start a job
1. The job, if running longer, will be timed out after **2 hours**

**Example 2 - Runner timeout not configured**

1. You remove the _maximum job timeout_ configuration from a runner
1. You set the _CI/CD Timeout_ for a project to **2 hours**
1. You start a job
1. The job, if running longer, will be timed out after **2 hours**

**Example 3 - Runner timeout smaller than project timeout**

1. You set the _maximum job timeout_ for a runner to **30 minutes**
1. You set the _CI/CD Timeout_ for a project to 2 hours
1. You start a job
1. The job, if running longer, will be timed out after **30 minutes**

## Be careful with sensitive information

With some [runner executors](https://docs.gitlab.com/runner/executors/README.html),
if you can run a job on the runner, you can get full access to the file system,
and thus any code it runs as well as the token of the runner. With shared runners, this means that anyone
that runs jobs on the runner, can access anyone else's code that runs on the
runner.

In addition, because you can get access to the runner token, it is possible
to create a clone of a runner and submit false jobs, for example.

The above is easily avoided by restricting the usage of shared runners
on large public GitLab instances, controlling access to your GitLab instance,
and using more secure [runner executors](https://docs.gitlab.com/runner/executors/README.html).

### Prevent runners from revealing sensitive information

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13194) in GitLab 10.0.

You can protect runners so they don't reveal sensitive information.
When a runner is protected, the runner picks jobs created on
[protected branches](../../user/project/protected_branches.md) or [protected tags](../../user/project/protected_tags.md) only,
and ignores other jobs.

To protect or unprotect a runner:

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. Find the runner you want to protect or unprotect. Make sure it's enabled.
1. Click the pencil button.
1. Check the **Protected** option.
1. Click **Save changes**.

![specific runners edit icon](img/protected_runners_check_box.png)

### Forks

Whenever a project is forked, it copies the settings of the jobs that relate
to it. This means that if you have shared runners set up for a project and
someone forks that project, the shared runners serve jobs of this project.

### Attack vectors in runners

Mentioned briefly earlier, but the following things of runners can be exploited.
We're always looking for contributions that can mitigate these
[Security Considerations](https://docs.gitlab.com/runner/security/).

### Reset the runner registration token for a project

If you think that a registration token for a project was revealed, you should
reset it. A token can be used to register another runner for the project. That new runner
may then be used to obtain the values of secret variables or to clone project code.

To reset the token:

1. Go to the project's **Settings > CI/CD**.
1. Expand the **General pipelines settings** section.
1. Find the **Runner token** form field and click the **Reveal value** button.
1. Delete the value and save the form.
1. After the page is refreshed, expand the **Runners settings** section
   and check the registration token - it should be changed.

From now on the old token is no longer valid and does not register
any new runners to the project. If you are using any tools to provision and
register new runners, the tokens used in those tools should be updated to reflect the
value of the new token.

## Determine the IP address of a runner

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17286) in GitLab 10.6.

It may be useful to know the IP address of a runner so you can troubleshoot
issues with that runner. GitLab stores and displays the IP address by viewing
the source of the HTTP requests it makes to GitLab when polling for jobs. The
IP address is always kept up to date so if the runner IP changes it will be
automatically updated in GitLab.

The IP address for shared runners and specific runners can be found in
different places.

### Determine the IP address of a shared runner

To view the IP address of a shared runner you must have admin access to
the GitLab instance. To determine this:

1. Visit **Admin Area > Overview > Runners**.
1. Look for the runner in the table and you should see a column for **IP Address**.

![shared runner IP address](img/shared_runner_ip_address.png)

### Determine the IP address of a specific runner

To can find the IP address of a runner for a specific project,
you must have Owner [permissions](../../user/permissions.md#project-members-permissions) for the project.

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. On the details page you should see a row for **IP Address**.

![specific runner IP address](img/specific_runner_ip_address.png)

## Use tags to limit the number of jobs using the runner

You must set up a runner to be able to run all the different types of jobs
that it may encounter on the projects it's shared over. This would be
problematic for large amounts of projects, if it weren't for tags. 

GitLab CI tags are not the same as Git tags. GitLab CI tags are associated with runners.
Git tags are associated with commits.

By tagging a runner for the types of jobs it can handle, you can make sure
shared runners will [only run the jobs they are equipped to run](../yaml/README.md#tags).

For instance, at GitLab we have runners tagged with `rails` if they contain
the appropriate dependencies to run Rails test suites.

When you [register a runner](https://docs.gitlab.com/runner/register/), its default behavior is to **only pick**
[tagged jobs](../yaml/README.md#tags).
To change this, you must have Owner [permissions](../../user/permissions.md#project-members-permissions) for the project.

To make a runner pick untagged jobs:

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. Find the runner you want to pick untagged jobs and make sure it's enabled.
1. Click the pencil button.
1. Check the **Run untagged jobs** option.
1. Click the **Save changes** button for the changes to take effect.

NOTE: **Note:**
The runner tags list can not be empty when it's not allowed to pick untagged jobs.

Below are some example scenarios of different variations.

### runner runs only tagged jobs

The following examples illustrate the potential impact of the runner being set
to run only tagged jobs.

Example 1:

1. The runner is configured to run only tagged jobs and has the `docker` tag.
1. A job that has a `hello` tag is executed and stuck.

Example 2:

1. The runner is configured to run only tagged jobs and has the `docker` tag.
1. A job that has a `docker` tag is executed and run.

Example 3:

1. The runner is configured to run only tagged jobs and has the `docker` tag.
1. A job that has no tags defined is executed and stuck.

### runner is allowed to run untagged jobs

The following examples illustrate the potential impact of the runner being set
to run tagged and untagged jobs.

Example 1:

1. The runner is configured to run untagged jobs and has the `docker` tag.
1. A job that has no tags defined is executed and run.
1. A second job that has a `docker` tag defined is executed and run.

Example 2:

1. The runner is configured to run untagged jobs and has no tags defined.
1. A job that has no tags defined is executed and run.
1. A second job that has a `docker` tag defined is stuck.

## System calls not available on GitLab.com shared runners

GitLab.com shared runners run on CoreOS. This means that you cannot use some system calls, like `getlogin`, from the C standard library.
