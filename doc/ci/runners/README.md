# Runners

In GitLab CI, Runners run the code defined in [`.gitlab-ci.yml`](../yaml/README.md).
They are isolated (virtual) machines that pick up jobs through the coordinator
API of GitLab CI.

A Runner can be specific to a certain project or serve any project
in GitLab CI. A Runner that serves all projects is called a shared Runner.

Ideally, the GitLab Runner should not be installed on the same machine as GitLab.
Read the [requirements documentation](../../install/requirements.md#gitlab-runner)
for more information.

## Shared vs specific Runners

After [installing the Runner][install], you can either register it as shared or
specific. You can only register a shared Runner if you have admin access to
the GitLab instance. The main differences between a shared and a specific Runner
are:

- **Shared Runners** are useful for jobs that have similar requirements,
  between multiple projects. Rather than having multiple Runners idling for
  many projects, you can have a single or a small number of Runners that handle
  multiple projects. This makes it easier to maintain and update them.
  Shared Runners process jobs using a [fair usage queue](#how-shared-runners-pick-jobs).
  In contrast to specific Runners that use a FIFO queue, this prevents
  cases where projects create hundreds of jobs which can lead to eating all
  available shared Runners resources.
- **Specific Runners** are useful for jobs that have special requirements or for
  projects with a specific demand. If a job has certain requirements, you can set
  up the specific Runner with this in mind, while not having to do this for all
  Runners. For example, if you want to deploy a certain project, you can setup
  a specific Runner to have the right credentials for this. The [usage of tags](#using-tags)
  may be useful in this case. Specific Runners process jobs using a [FIFO] queue.

A Runner that is specific only runs for the specified project(s). A shared Runner
can run jobs for every project that has enabled the option **Allow shared Runners**
under **Settings ➔ Pipelines**.

Projects with high demand of CI activity can also benefit from using specific
Runners. By having dedicated Runners you are guaranteed that the Runner is not
being held up by another project's jobs.

You can set up a specific Runner to be used by multiple projects. The difference
with a shared Runner is that you have to enable each project explicitly for
the Runner to be able to run its jobs.

Specific Runners do not get shared with forked projects automatically.
A fork does copy the CI settings (jobs, allow shared, etc) of the cloned
repository.

## Registering a shared Runner

You can only register a shared Runner if you are an admin of the GitLab instance.

1. Grab the shared-Runner token on the `admin/runners` page

    ![Shared Runners admin area](img/shared_runners_admin.png)

1. [Register the Runner][register]

Shared Runners are enabled by default as of GitLab 8.2, but can be disabled
with the **Disable shared Runners** button which is present under each project's
**Settings ➔ Pipelines** page. Previous versions of GitLab defaulted shared
Runners to disabled.

## Registering a specific Runner

Registering a specific can be done in two ways:

1. Creating a Runner with the project registration token
1. Converting a shared Runner into a specific Runner (one-way, admin only)

### Registering a specific Runner with a project registration token

To create a specific Runner without having admin rights to the GitLab instance,
visit the project you want to make the Runner work for in GitLab:

1. Go to **Settings ➔ Pipelines** to obtain the token
1. [Register the Runner][register]

### Making an existing shared Runner specific

If you are an admin on your GitLab instance, you can turn any shared Runner into
a specific one, but not the other way around. Keep in mind that this is a one
way transition.

1. Go to the Runners in the admin area **Overview ➔ Runners** (`/admin/runners`)
   and find your Runner
1. Enable any projects under **Restrict projects for this Runner** to be used
   with the Runner

From now on, the shared Runner will be specific to those projects.

## Locking a specific Runner from being enabled for other projects

You can configure a Runner to assign it exclusively to a project. When a
Runner is locked this way, it can no longer be enabled for other projects.
This setting can be enabled the first time you [register a Runner][register] and
can be changed afterwards under each Runner's settings.

To lock/unlock a Runner:

1. Visit your project's **Settings ➔ Pipelines**
1. Find the Runner you wish to lock/unlock and make sure it's enabled
1. Click the pencil button
1. Check the **Lock to current projects** option
1. Click **Save changes** for the changes to take effect

## How shared Runners pick jobs

Shared Runners abide to a process queue we call fair usage. The fair usage
algorithm tries to assign jobs to shared Runners from projects that have the
lowest number of jobs currently running on shared Runners.

**Example 1**

We have following jobs in queue:

- job 1 for project 1
- job 2 for project 1
- job 3 for project 1
- job 4 for project 2
- job 5 for project 2
- job 6 for project 3

With the fair usage algorithm jobs are assigned in following order:

1. We choose job 1, because project 1 doesn't run currently any jobs and has the lowest job number from projects that doesn't run jobs
1. We choose job 4, because project 2 doesn't run currently any jobs and has the lowest job number from projects that doesn't run jobs
1. We choose job 6, because project 3 doesn't run currently any jobs and has the lowest job number from projects that doesn't run jobs
1. We choose job 2, because project 1 as other it runs 1 job
1. We choose job 5, because project 2 runs 1 job, where project 1 runs 2 jobs now
1. We choose job 3, because project 1 and runs 2 jobs

---

**Example 2**

We have following jobs in queue:

- job 1 for project 1
- job 2 for project 1
- job 3 for project 1
- job 4 for project 2
- job 5 for project 2
- job 6 for project 3

With the fair usage algorithm jobs are assigned in following order:

1. We choose job 1, because project 1 doesn't run currently any jobs and has the lowest job number from projects that doesn't run jobs
1. We finish job 1
1. We choose job 2, because project 1 doesn't run currently any jobs and has the lowest job number from projects that doesn't run jobs
1. We choose job 4, because project 2 doesn't run currently any jobs and has the lowest job number from projects that doesn't run jobs
1. We finish job 4
1. We choose job 5, because project 2 doesn't run currently any jobs and has the lowest job number from projects that doesn't run jobs
1. We choose job 6, because project 3 doesn't run currently any jobs
1. We choose job 3, because project 1, 2 and 3 runs exactly one job now

## Using shared Runners effectively

If you are planning to use shared Runners, there are several things you
should keep in mind.

### Using tags

You must setup a Runner to be able to run all the different types of jobs
that it may encounter on the projects it's shared over. This would be
problematic for large amounts of projects, if it wasn't for tags.

By tagging a Runner for the types of jobs it can handle, you can make sure
shared Runners will only run the jobs they are equipped to run.

For instance, at GitLab we have Runners tagged with "rails" if they contain
the appropriate dependencies to run Rails test suites.

### Preventing Runners with tags from picking jobs without tags

You can configure a Runner to prevent it from picking jobs with tags when
the Runner does not have tags assigned. This setting can be enabled the first
time you [register a Runner][register] and can be changed afterwards under
each Runner's settings.

To make a Runner pick tagged/untagged jobs:

1. Visit your project's **Settings ➔ Pipelines**
1. Find the Runner you wish and make sure it's enabled
1. Click the pencil button
1. Check the **Run untagged jobs** option
1. Click **Save changes** for the changes to take effect

### Be careful with sensitive information

If you can run a job on a Runner, you can get access to any code it runs
and get the token of the Runner. With shared Runners, this means that anyone
that runs jobs on the Runner, can access anyone else's code that runs on the
Runner.

In addition, because you can get access to the Runner token, it is possible
to create a clone of a Runner and submit false jobs, for example.

The above is easily avoided by restricting the usage of shared Runners
on large public GitLab instances and controlling access to your GitLab instance.

### Forks

Whenever a project is forked, it copies the settings of the jobs that relate
to it. This means that if you have shared Runners setup for a project and
someone forks that project, the shared Runners will also serve jobs of this
project.

## Attack vectors in Runners

Mentioned briefly earlier, but the following things of Runners can be exploited.
We're always looking for contributions that can mitigate these
[Security Considerations](https://docs.gitlab.com/runner/security/).

[install]: http://docs.gitlab.com/runner/install/
[fifo]: https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics)
[register]: http://docs.gitlab.com/runner/register/
