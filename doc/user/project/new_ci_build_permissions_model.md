# New CI build permissions model

> Introduced in GitLab 8.12.

GitLab 8.12 has a completely redesigned [build permissions] system. You can find
all discussion and all our concerns when choosing the current approach in issue
[#18994](https://gitlab.com/gitlab-org/gitlab-ce/issues/18994).

---

Builds permissions should be tightly integrated with the permissions of a user
who is triggering a build.

The reasons to do it like that are:

- We already have a permissions system in place: group and project membership
  of users.
- We already fully know who is triggering a build (using `git push`, using the
  web UI, executing triggers).
- We already know what user is allowed to do.
- We use the user permissions for builds that are triggered by the user.
- It opens a lot of possibilities to further enforce user permissions, like
  allowing only specific users to access runners or use secure variables and
  environments.
- It is simple and convenient that your build can access everything that you
  as a user have access to.
- Short living unique tokens are now used, granting access for time of the build
  and maximizing security.

With the new behavior, any build that is triggered by the user, is also marked
with their permissions. When a user does a `git push` or changes files through
the web UI, a new pipeline will be usually created. This pipeline will be marked
as created be the pusher (local push or via the UI) and any build created in this
pipeline will have the permissions of the pusher.

This allows us to make it really easy to evaluate the access for all projects
that have Git submodules or are using container images that the pusher would
have access too. **The permission is granted only for time that build is running.
The access is revoked after the build is finished.**

## Types of users

It is important to note that we have a few types of users:

- **Administrators**: CI builds created by Administrators will not have access
  to all GitLab projects, but only to projects and container images of projects
  that the administrator is a member of.That means that if a project is either
  public or internal users have access anyway, but if a project is private, the
  Administrator will have to be a member of it in order to have access to it
  via another project's build.

- **External users**: CI builds created by [external users][ext] will have
  access only to projects to which user has at least reporter access. This
  rules out accessing all internal projects by default,

This allows us to make the CI and permission system more trustworthy.
Let's consider the following scenario:

1. You are an employee of a company. Your company has a number of internal tools
   hosted in private repositories and you have multiple CI builds that make use
   of these repositories.

2. You invite a new [external user][ext]. CI builds created by that user do not
   have access to internal repositories, because the user also doesn't have the
   access from within GitLab. You as an employee have to grant explicit access
   for this user. This allows us to prevent from accidental data leakage.

## Build token

A unique build token is generated for each build and it allows the user to
access all projects that would be normally accessible to the user creating that
build.

We try to make sure that this token doesn't leak by:

1. Securing all API endpoints to not expose the build token.
1. Masking the build token from build logs.
1. Allowing to use the build token **only** when build is running.

However, this brings a question about the Runners security. To make sure that
this token doesn't leak, you should also make sure that you configure
your Runners in the most possible secure way, by avoiding the following:

1. Any usage of Docker's `privileged` mode is risky if the machines are re-used.
1. Using the `shell` executor since builds run on the same machine.

By using an insecure GitLab Runner configuration, you allow the rogue developers
to steal the tokens of other builds.

## Debugging problems

With the new permission model in place, there may be times that your build will
fail. This is most likely because your project tries to access other project's
sources, and you don't have the appropriate permissions. In the build log look
for information about 403 or forbidden access messages

As an Administrator, you can verify that the user is a member of the group or
project they're trying to have access to, and you can impersonate the user to
retry the failing build in order to verify that everything is correct.

## Build triggers

[Build triggers][triggers] do not support the new permission model.
They continue to use the old authentication mechanism where the CI build
can access only its own sources. We plan to remove that limitation in one of
the upcoming releases.

## Before GitLab 8.12

In versions before GitLab 8.12, all CI builds would use the CI Runner's token
to checkout project sources.

The project's Runner's token was a token that you could find under the
project's **Settings > CI/CD Pipelines** and was limited to access only that
project.
It could be used for registering new specific Runners assigned to the project
and to checkout project sources.
It could also be used with the GitLab Container Registry for that project,
allowing pulling and pushing Docker images from within the CI build.

---

GitLab would create a special checkout URL like:

```
https://gitlab-ci-token:<project-runners-token>/gitlab.com/gitlab-org/gitlab-ce.git
```

And then the users could also use it in their CI builds all Docker related
commands to interact with GitLab Container Registry. For example:

```
docker login -u gitlab-ci-token -p $CI_BUILD_TOKEN registry.gitlab.com
```

Using single token had multiple security implications:

- The token would be readable to anyone who had developer access to a project
  that could run CI builds, allowing the developer to register any specific
  Runner for that project.
- The token would allow to access only the project's sources, forbidding from
  accessing any other projects.
- The token was not expiring and was multi-purpose: used for checking out sources,
  for registering specific runners and for accessing a project's container
  registry with read-write permissions.

All the above led to a new permission model for builds that was introduced
with GitLab 8.12.

## Making use of the new CI build permissions model

With the new build permission model, there is now an easy way to access all
dependent source code in a project. That way, we can:

1. Access a project's Git submodules
1. Access private container images
1. Access project's and submodule LFS objects

Let's see how that works with Git submodules and private Docker images hosted on
the container registry.

## Git submodules

>
It often happens that while working on one project, you need to use another
project from within it; perhaps it’s a library that a third party developed or
you’re developing a project separately and are using it in multiple parent
projects.
A common issue arises in these scenarios: you want to be able to treat the two
projects as separate yet still be able to use one from within the other.
>
_Excerpt from the [Git website][git-scm] about submodules._

If dealing with submodules, your project will probably have a file named
`.gitmodules`. And this is how it usually looks like:

```
[submodule "tools"]
	path = tools
	url = git@gitlab.com/group/tools.git
```

> **Note:**
If you are **not** using GitLab 8.12 or higher, you would need to work your way
around this issue in order to access the sources of `gitlab.com/group/tools`
(e.g., use [SSH keys](../ssh_keys/README.md)).
>
With GitLab 8.12 onward, your permissions are used to evaluate what a CI build
can access. More information about how this system works can be found in the
[Build permissions model](../../user/permissions.md#builds-permissions).

To make use of the new changes, you have to update your `.gitmodules` file to
use a relative URL.

Let's consider the following example:

1. Your project is located at `https://gitlab.com/secret-group/my-project`.
1. To checkout your sources you usually use an SSH address like
   `git@gitlab.com:secret-group/my-project.git`.
1. Your project depends on `https://gitlab.com/group/tools`.
1. You have the `.gitmodules` file with above content.

Since Git allows the usage of relative URLs for your `.gitmodules` configuration,
this easily allows you to use HTTP for cloning all your CI builds and SSH
for all your local checkouts.

For example, if you change the `url` of your `tools` dependency, from
`git@gitlab.com/group/tools.git` to `../../group/tools.git`, this will instruct
Git to automatically deduce the URL that should be used when cloning sources.
Whether you use HTTP or SSH, Git will use that same channel and it will allow
to make all your CI builds use HTTPS (because GitLab CI uses HTTPS for cloning
your sources), and all your local clones will continue using SSH.

Given the above explanation, your `.gitmodules` file should eventually look
like this:

```
[submodule "tools"]
	path = tools
	url = ../../group/tools.git
```

However, you have to explicitly tell GitLab CI to clone your submodules as this
is not done automatically. You can achieve that by adding a `before_script`
section to your `.gitlab-ci.yml`:

```
before_script:
  - git submodule update --init --recursive

test:
  script:
    - run-my-tests
```

This will make GitLab CI initialize (fetch) and update (checkout) all your
submodules recursively.

In case your environment or your Docker image doesn't have Git installed,
you have to either ask your Administrator or install the missing dependency
yourself:

```
# Debian / Ubuntu
before_script:
  - apt-get update -y
  - apt-get install -y git-core
  - git submodule update --init --recursive

# CentOS / RedHat
before_script:
  - yum install git
  - git submodule update --init --recursive

# Alpine
before_script:
  - apk add -U git
  - git submodule update --init --recursive
```

### Container Registry

With the update permission model we also extended the support for accessing
Container Registries for private projects.

> **Note:**
As GitLab Runner 1.6 doesn't yet incorporate the introduced changes for
permissions, this makes the `image:` directive to not work with private projects
automatically. The manual configuration by an Administrator is required to use
private images. We plan to remove that limitation in one of the upcoming releases.

Your builds can access all container images that you would normally have access
to. The only implication is that you can push to the Container Registry of the
project for which the build is triggered.

This is how an example usage can look like:

```
test:
  script:
    - docker login -u gitlab-ci-token -p $CI_BUILD_TOKEN $CI_REGISTRY
    - docker pull $CI_REGISTRY/group/other-project:latest
    - docker run $CI_REGISTRY/group/other-project:latest
```

[git-scm]: https://git-scm.com/book/en/v2/Git-Tools-Submodules
[build permissions]: ../permissions.md#builds-permissions
[ext]: ../permissions.md#external-users
[triggers]: ../../ci/triggers/README.md
