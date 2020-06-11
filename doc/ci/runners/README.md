---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference
---

# Configuring GitLab Runners

In GitLab CI/CD, Runners run the code defined in [`.gitlab-ci.yml`](../yaml/README.md).
A GitLab Runner is a lightweight, highly-scalable agent that picks up a CI job through
the coordinator API of GitLab CI/CD, runs the job, and sends the result back to the GitLab instance.

Runners are created by an administrator and are visible in the GitLab UI.
Runners can be specific to certain projects or available to all projects.

## Types of Runners

There are three types of Runners:

- [Shared](#shared-runners) (for all projects)
- [Group](#group-runners) (for all projects in a group)
- [Specific](#specific-runners) (for specific projects)

If you are running self-managed GitLab, you can create your own Runners.

If you are using GitLab.com, you can use the shared Runners provided by GitLab or
create your own group or specific Runners.

### Shared Runners

*Shared Runners* are available to every project in a GitLab instance.

Use shared Runners when you have multiple jobs with similar requirements. Rather than
having multiple Runners idling for many projects, you can have a few Runners that handle
multiple projects.

If you are using a self-managed instance of GitLab, your administrator can create
shared Runners and configure them to use the
[executor](https://docs.gitlab.com/runner/executors/README.html) you want.

If you are using GitLab.com, you can select from a list of
[shared Runners that GitLab maintains](../../user/gitlab_com/index.md#shared-runners).

#### How shared Runners pick jobs

Shared Runners process jobs by using a fair usage queue. This queue prevents
projects from creating hundreds of jobs and using all available
shared Runner resources.

The fair usage queue algorithm assigns jobs based on the projects that have the
fewest number of jobs already running on shared Runners.

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

- Job 1 for project 1
- Job 2 for project 1
- Job 3 for project 1
- Job 4 for project 2
- Job 5 for project 2
- Job 6 for project 3

The fair usage algorithm assigns jobs in this order:

1. Job 1 is chosen first, because it has the lowest job number from projects with no running jobs (that is, all projects).
1. We finish job 1.
1. Job 2 is next, because, having finished Job 1, all projects have 0 jobs running again, and 2 is the lowest available job number.
1. Job 4 is next, because with Project 1 running a job, 4 is the lowest number from projects running no jobs (Projects 2 and 3).
1. We finish job 4.
1. Job 5 is next, because having finished Job 4, Project 2 has no jobs running again.
1. Job 6 is next, because Project 3 is the only project left with no running jobs.
1. Lastly we choose Job 3... because, again, it's the only job left.

#### Enable a shared Runner

By default, all projects can use shared Runners, and they are enabled by default.

However, you can enable or disable shared Runners for individual projects.

To enable or disable a shared Runner:

1. Go to the project's **{settings}** **Settings > CI/CD** and expand the **Runners** section.
1. Click **Allow shared Runners** or **Disable shared Runners**.

### Group Runners

Use *Group Runners* when you want all projects in a group
to have access to a set of Runners.

Group Runners process jobs by using a first in, first out ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) queue.

#### Create a group Runner

You can create a group Runner for your self-managed GitLab instance or for GitLab.com.
You must have [Owner permissions](../../user/permissions.md#group-members-permissions) for the group.

To create a group Runner:

1. [Install Runner](https://docs.gitlab.com/runner/install/).
1. Go to the group you want to make the Runner work for.
1. Go to **{settings}** **Settings > CI/CD** and expand the **Runners** section.
1. Note the URL and token.
1. [Register the Runner](https://docs.gitlab.com/runner/register/).

#### Pause or remove a group Runner

You can pause or remove a group Runner.
You must have [Owner permissions](../../user/permissions.md#group-members-permissions) for the group.

1. Go to the group you want to remove or pause the Runner for.
1. Go to **{settings}** **Settings > CI/CD** and expand the **Runners** section.
1. Click **Pause** or **Remove Runner**.
1. On the confirmation dialog, click **OK**.

### Specific Runners

Use *Specific Runners* when you want to use Runners for specific projects. For example,
when you have:

- Jobs with specific requirements, like a deploy job that requires credentials.
- Projects with a lot of CI activity that can benefit from being separate from other Runners.

You can set up a specific Runner to be used by multiple projects. Specific Runners
must be enabled for each project explicitly.

Specific Runners process jobs by using a first in, first out ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) queue.

NOTE: **Note:**
Specific Runners do not get shared with forked projects automatically.
A fork *does* copy the CI / CD settings of the cloned repository.

#### Create a specific Runner

You can create a specific Runner for your self-managed GitLab instance or for GitLab.com.
You must have [Owner permissions](../../user/permissions.md#project-members-permissions) for the project.

To create a specific Runner:

1. [Install Runner](https://docs.gitlab.com/runner/install/).
1. Go to the project's **{settings}** **Settings > CI/CD** and expand the **Runners** section.
1. Note the URL and token.
1. [Register the Runner](https://docs.gitlab.com/runner/register/).

#### Enable a specific Runner for a specific project

A specific Runner is available in the project it was created for. An administrator can
enable a specific Runner to apply to additional projects.

- You must have Owner permissions for the project.
- The specific Runner must not be [locked](#prevent-a-specific-runner-from-being-enabled-for-other-projects).

To enable or disable a specific Runner for a project:

1. Go to the project's **{settings}** **Settings > CI/CD** and expand the **Runners** section.
1. Click **Enable for this project** or **Disable for this project**.

#### Prevent a specific Runner from being enabled for other projects

You can configure a specific Runner so it is "locked" and cannot be enabled for other projects.
This setting can be enabled when you first [register a Runner](https://docs.gitlab.com/runner/register/),
but can also be changed later.

To lock or unlock a Runner:

1. Go to the project's **{settings}** **Settings > CI/CD** and expand the **Runners** section.
1. Find the Runner you want to lock or unlock. Make sure it's enabled.
1. Click the pencil button.
1. Check the **Lock to current projects** option.
1. Click **Save changes**.

## Manually clear the Runner cache

Read [clearing the cache](../caching/index.md#clearing-the-cache).

## Set maximum job timeout for a Runner

For each Runner, you can specify a *maximum job timeout*. This timeout,
if smaller than the [project defined timeout](../pipelines/settings.md#timeout), takes precedence.

This feature can be used to prevent your shared Runner from being overwhelmed
by a project that has jobs with a long timeout (for example, one week).

When not configured, Runners will not override the project timeout.

How this feature works:

**Example 1 - Runner timeout bigger than project timeout**

1. You set the _maximum job timeout_ for a Runner to 24 hours
1. You set the _CI/CD Timeout_ for a project to **2 hours**
1. You start a job
1. The job, if running longer, will be timed out after **2 hours**

**Example 2 - Runner timeout not configured**

1. You remove the _maximum job timeout_ configuration from a Runner
1. You set the _CI/CD Timeout_ for a project to **2 hours**
1. You start a job
1. The job, if running longer, will be timed out after **2 hours**

**Example 3 - Runner timeout smaller than project timeout**

1. You set the _maximum job timeout_ for a Runner to **30 minutes**
1. You set the _CI/CD Timeout_ for a project to 2 hours
1. You start a job
1. The job, if running longer, will be timed out after **30 minutes**

## Be careful with sensitive information

With some [Runner Executors](https://docs.gitlab.com/runner/executors/README.html),
if you can run a job on the Runner, you can get full access to the file system,
and thus any code it runs as well as the token of the Runner. With shared Runners, this means that anyone
that runs jobs on the Runner, can access anyone else's code that runs on the
Runner.

In addition, because you can get access to the Runner token, it is possible
to create a clone of a Runner and submit false jobs, for example.

The above is easily avoided by restricting the usage of shared Runners
on large public GitLab instances, controlling access to your GitLab instance,
and using more secure [Runner Executors](https://docs.gitlab.com/runner/executors/README.html).

### Prevent Runners from revealing sensitive information

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13194) in GitLab 10.0.

You can protect Runners so they don't reveal sensitive information.
When a Runner is protected, the Runner picks jobs created on
[protected branches](../../user/project/protected_branches.md) or [protected tags](../../user/project/protected_tags.md) only,
and ignores other jobs.

To protect or unprotect a Runner:

1. Go to the project's **{settings}** **Settings > CI/CD** and expand the **Runners** section.
1. Find the Runner you want to protect or unprotect. Make sure it's enabled.
1. Click the pencil button.
1. Check the **Protected** option.
1. Click **Save changes**.

![specific Runners edit icon](img/protected_runners_check_box.png)

### Forks

Whenever a project is forked, it copies the settings of the jobs that relate
to it. This means that if you have shared Runners set up for a project and
someone forks that project, the shared Runners will also serve jobs of this
project.

### Attack vectors in Runners

Mentioned briefly earlier, but the following things of Runners can be exploited.
We're always looking for contributions that can mitigate these
[Security Considerations](https://docs.gitlab.com/runner/security/).

### Reset the Runner registration token for a project

If you think that a registration token for a project was revealed, you should
reset it. A token can be used to register another Runner for the project. That new Runner
may then be used to obtain the values of secret variables or to clone project code.

To reset the token:

1. Go to the project's **{settings}** **Settings > CI/CD**.
1. Expand the **General pipelines settings** section.
1. Find the **Runner token** form field and click the **Reveal value** button.
1. Delete the value and save the form.
1. After the page is refreshed, expand the **Runners settings** section
   and check the registration token - it should be changed.

From now on the old token is no longer valid and will not register
any new Runners to the project. If you are using any tools to provision and
register new Runners, the tokens used in those tools should be updated to reflect the
value of the new token.

## Determine the IP address of a Runner

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17286) in GitLab 10.6.

It may be useful to know the IP address of a Runner so you can troubleshoot
issues with that Runner. GitLab stores and displays the IP address by viewing
the source of the HTTP requests it makes to GitLab when polling for jobs. The
IP address is always kept up to date so if the Runner IP changes it will be
automatically updated in GitLab.

The IP address for shared Runners and specific Runners can be found in
different places.

### Determine the IP address of a shared Runner

To view the IP address of a shared Runner you must have admin access to
the GitLab instance. To determine this:

1. Visit **{admin}** **Admin Area > Overview > Runners**.
1. Look for the Runner in the table and you should see a column for **IP Address**.

![shared Runner IP address](img/shared_runner_ip_address.png)

### Determine the IP address of a specific Runner

To can find the IP address of a Runner for a specific project,
you must have Owner [permissions](../../user/permissions.md#project-members-permissions) for the project.

1. Go to the project's **{settings}** **Settings > CI/CD** and expand the **Runners** section.
1. On the details page you should see a row for **IP Address**.

![specific Runner IP address](img/specific_runner_ip_address.png)

## Use tags to limit the number of jobs using the Runner

You must set up a Runner to be able to run all the different types of jobs
that it may encounter on the projects it's shared over. This would be
problematic for large amounts of projects, if it weren't for tags.

By tagging a Runner for the types of jobs it can handle, you can make sure
shared Runners will [only run the jobs they are equipped to run](../yaml/README.md#tags).

For instance, at GitLab we have Runners tagged with `rails` if they contain
the appropriate dependencies to run Rails test suites.

When you [register a Runner](https://docs.gitlab.com/runner/register/), its default behavior is to **only pick**
[tagged jobs](../yaml/README.md#tags).
To change this, you must have Owner [permissions](../../user/permissions.md#project-members-permissions) for the project.

To make a Runner pick untagged jobs:

1. Go to the project's **{settings}** **Settings > CI/CD** and expand the **Runners** section.
1. Find the Runner you want to pick untagged jobs and make sure it's enabled.
1. Click the pencil button.
1. Check the **Run untagged jobs** option.
1. Click the **Save changes** button for the changes to take effect.

NOTE: **Note:**
The Runner tags list can not be empty when it's not allowed to pick untagged jobs.

Below are some example scenarios of different variations.

### Runner runs only tagged jobs

The following examples illustrate the potential impact of the Runner being set
to run only tagged jobs.

Example 1:

1. The Runner is configured to run only tagged jobs and has the `docker` tag.
1. A job that has a `hello` tag is executed and stuck.

Example 2:

1. The Runner is configured to run only tagged jobs and has the `docker` tag.
1. A job that has a `docker` tag is executed and run.

Example 3:

1. The Runner is configured to run only tagged jobs and has the `docker` tag.
1. A job that has no tags defined is executed and stuck.

### Runner is allowed to run untagged jobs

The following examples illustrate the potential impact of the Runner being set
to run tagged and untagged jobs.

Example 1:

1. The Runner is configured to run untagged jobs and has the `docker` tag.
1. A job that has no tags defined is executed and run.
1. A second job that has a `docker` tag defined is executed and run.

Example 2:

1. The Runner is configured to run untagged jobs and has no tags defined.
1. A job that has no tags defined is executed and run.
1. A second job that has a `docker` tag defined is stuck.
