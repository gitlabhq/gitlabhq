# Runners

In GitLab CI, Runners run your [yaml](../yaml/README.md).
A runner is an isolated (virtual) machine that picks up builds
through the coordinator API of GitLab CI.

A runner can be specific to a certain project or serve any project
in GitLab CI. A runner that serves all projects is called a shared runner.

Ideally, GitLab Runner should not be installed on the same machine as GitLab.
Read the [requirements documentation](../../install/requirements.md#gitlab-runner)
for more information.

## Shared vs. Specific Runners

A runner that is specific only runs for the specified project. A shared runner
can run jobs for every project that has enabled the option
`Allow shared runners`.

**Shared runners** are useful for jobs that have similar requirements,
between multiple projects. Rather than having multiple runners idling for
many projects, you can have a single or a small number of runners that handle
multiple projects. This makes it easier to maintain and update runners.

**Specific runners** are useful for jobs that have special requirements or for
projects with a specific demand. If a job has certain requirements, you can set
up the specific runner with this in mind, while not having to do this for all
runners. For example, if you want to deploy a certain project, you can setup
a specific runner to have the right credentials for this.

Projects with high demand of CI activity can also benefit from using specific runners.
By having dedicated runners you are guaranteed that the runner is not being held
up by another project's jobs.

You can set up a specific runner to be used by multiple projects. The difference
with a shared runner is that you have to enable each project explicitly for
the runner to be able to run its jobs.

Specific runners do not get shared with forked projects automatically.
A fork does copy the CI settings (jobs, allow shared, etc) of the cloned repository.

# Creating and Registering a Runner

There are several ways to create a runner. Only after creation, upon
registration its status as Shared or Specific is determined.

[See the documentation for](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/#installation)
the different methods of installing a Runner instance.

After installing the runner, you can either register it as `Shared` or as `Specific`.
You can only register a Shared Runner if you have admin access to the GitLab instance.

## Registering a Shared Runner

You can only register a shared runner if you are an admin on the linked
GitLab instance.

Grab the shared-runner token on the `admin/runners` page of your GitLab CI
instance.

![shared token](shared_runner.png)

Now simply register the runner as any runner:

```
sudo gitlab-ci-multi-runner register
```

Shared runners are enabled by default as of GitLab 8.2, but can be disabled with the
`DISABLE SHARED RUNNERS` button. Previous versions of GitLab defaulted shared runners to
disabled.

## Registering a Specific Runner

Registering a specific can be done in two ways:

1. Creating a runner with the project registration token
1. Converting a shared runner into a specific runner (one-way, admin only)

There are several ways to create a runner instance. The steps below only
concern registering the runner on GitLab CI.

###  Registering a Specific Runner with a Project Registration token

To create a specific runner without having admin rights to the GitLab instance,
visit the project you want to make the runner work for in GitLab CI.

Click on the runner tab and use the registration token you find there to
setup a specific runner for this project.

![project runners in GitLab CI](project_specific.png)

To register the runner, run the command below and follow instructions:

```
sudo gitlab-ci-multi-runner register
```

###  Lock a specific runner from being enabled for other projects

You can configure a runner to assign it exclusively to a project. When a
runner is locked this way, it can no longer be enabled for other projects.
This setting is available on each runner in *Project Settings* > *Runners*.

###  Making an existing Shared Runner Specific

If you are an admin on your GitLab instance,
you can make any shared runner a specific runner, _but you can not
make a specific runner a shared runner_.

To make a shared runner specific, go to the runner page (`/admin/runners`)
and find your runner. Add any projects on the left to make this runner
run exclusively for these projects, therefore making it a specific runner.

![making a shared runner specific](shared_to_specific_admin.png)

## Using Shared Runners Effectively

If you are planning to use shared runners, there are several things you
should keep in mind.

### Use Tags

You must setup a runner to be able to run all the different types of jobs
that it may encounter on the projects it's shared over. This would be
problematic for large amounts of projects, if it wasn't for tags.

By tagging a Runner for the types of jobs it can handle, you can make sure
shared runners will only run the jobs they are equipped to run.

For instance, at GitLab we have runners tagged with "rails" if they contain
the appropriate dependencies to run Rails test suites.

### Prevent runner with tags from picking jobs without tags

You can configure a runner to prevent it from picking jobs with tags when
the runner does not have tags assigned. This setting is available on each
runner in *Project Settings* > *Runners*.

### Be careful with sensitive information

If you can run a build on a runner, you can get access to any code it runs
and get the token of the runner. With shared runners, this means that anyone
that runs jobs on the runner, can access anyone else's code that runs on the runner.

In addition, because you can get access to the runner token, it is possible
to create a clone of a runner and submit false builds, for example.

The above is easily avoided by restricting the usage of shared runners
on large public GitLab instances and controlling access to your GitLab instance.

### Forks

Whenever a project is forked, it copies the settings of the jobs that relate
to it. This means that if you have shared runners setup for a project and
someone forks that project, the shared runners will also serve jobs of this
project.

## Attack vectors in Runners

Mentioned briefly earlier, but the following things of runners can be exploited.
We're always looking for contributions that can mitigate these [Security Considerations](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/blob/master/docs/security/index.md).
