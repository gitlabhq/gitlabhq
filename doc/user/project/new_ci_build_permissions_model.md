# New CI job permissions model

> Introduced in GitLab 8.12.

GitLab 8.12 has a completely redesigned [job permissions] system. You can find
all discussion and all our concerns when choosing the current approach in issue
[#18994](https://gitlab.com/gitlab-org/gitlab-ce/issues/18994).

---

Jobs permissions should be tightly integrated with the permissions of a user
who is triggering a job.

The reasons to do it like that are:

- We already have a permissions system in place: group and project membership
  of users.
- We already fully know who is triggering a job (using `git push`, using the
  web UI, executing triggers).
- We already know what user is allowed to do.
- We use the user permissions for jobs that are triggered by the user.
- It opens a lot of possibilities to further enforce user permissions, like
  allowing only specific users to access runners or use secure variables and
  environments.
- It is simple and convenient that your job can access everything that you
  as a user have access to.
- Short living unique tokens are now used, granting access for time of the job
  and maximizing security.

With the new behavior, any job that is triggered by the user, is also marked
with their permissions. When a user does a `git push` or changes files through
the web UI, a new pipeline will be usually created. This pipeline will be marked
as created be the pusher (local push or via the UI) and any job created in this
pipeline will have the permissions of the pusher.

This allows us to make it really easy to evaluate the access for all projects
that have [Git submodules][gitsub] or are using container images that the pusher
would have access too. **The permission is granted only for time that job is
running. The access is revoked after the job is finished.**

## Types of users

It is important to note that we have a few types of users:

- **Administrators**: CI jobs created by Administrators will not have access
  to all GitLab projects, but only to projects and container images of projects
  that the administrator is a member of.That means that if a project is either
  public or internal users have access anyway, but if a project is private, the
  Administrator will have to be a member of it in order to have access to it
  via another project's job.

- **External users**: CI jobs created by [external users][ext] will have
  access only to projects to which user has at least reporter access. This
  rules out accessing all internal projects by default,

This allows us to make the CI and permission system more trustworthy.
Let's consider the following scenario:

1. You are an employee of a company. Your company has a number of internal tools
   hosted in private repositories and you have multiple CI jobs that make use
   of these repositories.

2. You invite a new [external user][ext]. CI jobs created by that user do not
   have access to internal repositories, because the user also doesn't have the
   access from within GitLab. You as an employee have to grant explicit access
   for this user. This allows us to prevent from accidental data leakage.

## Job token

A unique job token is generated for each job and it allows the user to
access all projects that would be normally accessible to the user creating that
job.

We try to make sure that this token doesn't leak by:

1. Securing all API endpoints to not expose the job token.
1. Masking the job token from job logs.
1. Allowing to use the job token **only** when job is running.

However, this brings a question about the Runners security. To make sure that
this token doesn't leak, you should also make sure that you configure
your Runners in the most possible secure way, by avoiding the following:

1. Any usage of Docker's `privileged` mode is risky if the machines are re-used.
1. Using the `shell` executor since jobs run on the same machine.

By using an insecure GitLab Runner configuration, you allow the rogue developers
to steal the tokens of other jobs.

## Pipeline triggers

Since 9.0 [pipeline triggers][triggers] do support the new permission model.
The new triggers do impersonate their associated user including their access
to projects and their project permissions. To migrate trigger to use new permission
model use **Take ownership**.

## Before GitLab 8.12

In versions before GitLab 8.12, all CI jobs would use the CI Runner's token
to checkout project sources.

The project's Runner's token was a token that you could find under the
project's **Settings > Pipelines** and was limited to access only that
project.
It could be used for registering new specific Runners assigned to the project
and to checkout project sources.
It could also be used with the GitLab Container Registry for that project,
allowing pulling and pushing Docker images from within the CI job.

---

GitLab would create a special checkout URL like:

```
https://gitlab-ci-token:<project-runners-token>/gitlab.com/gitlab-org/gitlab-ce.git
```

And then the users could also use it in their CI jobs all Docker related
commands to interact with GitLab Container Registry. For example:

```
docker login -u gitlab-ci-token -p $CI_JOB_TOKEN registry.gitlab.com
```

Using single token had multiple security implications:

- The token would be readable to anyone who had developer access to a project
  that could run CI jobs, allowing the developer to register any specific
  Runner for that project.
- The token would allow to access only the project's sources, forbidding from
  accessing any other projects.
- The token was not expiring and was multi-purpose: used for checking out sources,
  for registering specific runners and for accessing a project's container
  registry with read-write permissions.

All the above led to a new permission model for jobs that was introduced
with GitLab 8.12.

## Making use of the new CI job permissions model

With the new job permissions model, there is now an easy way to access all
dependent source code in a project. That way, we can:

1. Access a project's dependent repositories
1. Access a project's [Git submodules][gitsub]
1. Access private container images
1. Access project's and submodule LFS objects

Below you can see the prerequisites needed to make use of the new permissions
model and how that works with Git submodules and private Docker images hosted on
the container registry.

### Prerequisites to use the new permissions model

With the new permissions model in place, there may be times that your job will
fail. This is most likely because your project tries to access other project's
sources, and you don't have the appropriate permissions. In the job log look
for information about 403 or forbidden access messages.

In short here's what you need to do should you encounter any issues.

As an administrator:

- **500 errors**: You will need to update [GitLab Workhorse][workhorse] to at
  least 0.8.2. This is done automatically for Omnibus installations, you need to
  [check manually][update-docs] for installations from source.
- **500 errors**: Check if you have another web proxy sitting in front of NGINX (HAProxy,
  Apache, etc.). It might be a good idea to let GitLab use the internal NGINX
  web server and not disable it completely. See [this comment][comment] for an
  example.
- **403 errors**: You need to make sure that your installation has [HTTP(S)
  cloning enabled][https]. HTTP(S) support is now a **requirement** by GitLab CI
  to clone all sources.

As a user:

- Make sure you are a member of the group or project you're trying to have
  access to. As an Administrator, you can verify that by impersonating the user
  and retry the failing job in order to verify that everything is correct.

### Dependent repositories

The [Job environment variable][jobenv] `CI_JOB_TOKEN` can be used to
authenticate any clones of dependent repositories. For example:

```
git clone https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/myuser/mydependentrepo
```

It can also be used for system-wide authentication
(only do this in a docker container, it will overwrite ~/.netrc):

```
echo -e "machine gitlab.com\nlogin gitlab-ci-token\npassword ${CI_JOB_TOKEN}" > ~/.netrc
```

### Git submodules

To properly configure submodules with GitLab CI, read the
[Git submodules documentation][gitsub].

### Container Registry

With the update permission model we also extended the support for accessing
Container Registries for private projects.

> **Notes:**
- GitLab Runner versions prior to 1.8 don't incorporate the introduced changes
  for permissions. This makes the `image:` directive to not work with private
  projects automatically and it needs to be configured manually on Runner's host
  with a predefined account (for example administrator's personal account with
  access token created explicitly for this purpose). This issue is resolved with
  latest changes in GitLab Runner 1.8 which receives GitLab credentials with
  build data.
- Starting from GitLab 8.12, if you have [2FA] enabled in your account, you need
  to pass a [personal access token][pat] instead of your password in order to
  login to GitLab's Container Registry.

Your jobs can access all container images that you would normally have access
to. The only implication is that you can push to the Container Registry of the
project for which the job is triggered.

This is how an example usage can look like:

```
test:
  script:
    - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
    - docker pull $CI_REGISTRY/group/other-project:latest
    - docker run $CI_REGISTRY/group/other-project:latest
```

[job permissions]: ../permissions.md#job-permissions
[comment]: https://gitlab.com/gitlab-org/gitlab-ce/issues/22484#note_16648302
[ext]: ../permissions.md#external-users
[gitsub]: ../../ci/git_submodules.md
[https]: ../admin_area/settings/visibility_and_access_controls.md#enabled-git-access-protocols
[triggers]: ../../ci/triggers/README.md
[update-docs]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/update
[workhorse]: https://gitlab.com/gitlab-org/gitlab-workhorse
[jobenv]: ../../ci/variables/README.md#predefined-variables-environment-variables
[2fa]: ../profile/account/two_factor_authentication.md
[pat]: ../profile/personal_access_tokens.md
