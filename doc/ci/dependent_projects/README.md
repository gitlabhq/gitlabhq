## Dependent projects

> Introduced in GitLab 8.12.

GitLab 8.12 introduces a new [Build permissions model](../../user/permissions.md#builds-permissions).

This opens an easy to use a way to access all dependent source codes:
1. Access project's `submodule`,
1. Access private Container Images,
1. Access project's and submodule LFS objects.

### Submodules

> It often happens that while working on one project, you need to use another project from within it.
> Perhaps it’s a library that a third party developed or that you’re developing separately and using in multiple parent projects.
> A common issue arises in these scenarios: you want to be able to treat the two projects as separate yet still be able to use one from within the other.
> (from https://git-scm.com/book/en/v2/Git-Tools-Submodules)

Your project usually have a file named `.gitmodules`.
This file usually looks like that:
```
[submodule "tools"]
	path = tools
	url = git@gitlab.com/group/tools.git
```

Before 8.12 you had to do a multiple workarounds (ex. [SSH keys](../ssh_keys/README.md))
in order to access the sources of `gitlab.com/group/tools`.

GitLab 8.12 uses your permissions to evaluate what a CI build can access.
More information about how this system works can be found here: [Build permissions model](../../user/permissions.md#builds-permissions).

To make use of a new changes you have to update your `.gitmodules` file to use a relative URL.

Let's consider the following example:

1. Your project is located at https://gitlab.com/secret-group/my-project,
1. To checkout your sources you usually use a SSH address: `git@gitlab.com:secret-group/my-project.git`,
1. Your project depend on https://gitlab.com/group/tools,
1. You have the `.gitmodules` file with above content.

Since that you can use a relative URLs for your `.gitmodules` configuration
it easily allows you to use an HTTP cloning for all your CI builds,
and SSH clonning for all your local checkouts.

If you change the `url` of your `tools` dependency:
```
git@gitlab.com/group/tools.git => ../../group/tools.git
```

It will instruct GIT to automatically deduce a URL that should be used when cloning sources.
Whether you used a HTTP or SSH it will instruct GIT to use the same channel.
And this will allow to make all your CI builds to use HTTPS (because GitLab CI uses HTTPS for cloning your sources),
and all your local clones will continue using SSH.

Given the above explanation, your `.gitmodules` file should look like this:
```
[submodule "tools"]
	path = tools
	url = ../../group/tools.git
```

However, you have to instruct GitLab CI to clone your submodules as this is not done automatically.
You can achieve that by adding a `before_script` section to your `.gitlab-ci.yml` with `git submodule` command:

```
before_script:
  - git submodule update --init --recursive

test:
  script:
    - run-my-tests
```

This will make GitLab CI to initialize (fetch) and update (checkout) all your submodules recursively.

It can happen that your environment or your Docker Image does not have a git installed.
You have to either ask your Administrator or install the missing dependency yourself:

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

With the update permission model we also extended support for accessing Container Registries for private projects.

> Note: As of 1.6 the GitLab Runner doesn't yet incorporate the introduced changes for permissions.
> This makes a `image:` to not work with private projects automatically.
> The manual configuration by Administrator is required to use private images.
> We plan to remove that limitation in one of the upcoming releases.

Your builds can access all container images that you would normally have access to.
The only implication is that you can push to Container Registry of project for which the build is triggered.

This is how the example usage can look like:
```
test:
  script:
    - docker login -u gitlab-ci-token -p $CI_BUILD_TOKEN $CI_REGISTRY
    - docker pull $CI_REGISTRY/group/other-project:latest
    - docker run $CI_REGISTRY/group/other-project:latest
```
