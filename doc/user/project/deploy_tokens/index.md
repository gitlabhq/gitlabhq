---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deploy tokens
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use a deploy token to enable authentication of deployment tasks, independent of a user
account. In most cases you use a deploy token from an external host, like a build server or CI/CD
server.

With a deploy token, automated tasks can:

- Clone Git repositories.
- Pull from and push to a GitLab container registry.
- Pull from and push to a GitLab package registry.

A deploy token is a pair of values:

- **username**: `username` in the HTTP authentication framework. The default username format is
  `gitlab+deploy-token-{n}`. You can specify a custom username when you create the deploy token.
- **token**: `password` in the HTTP authentication framework.

Deploy tokens do not support [SSH authentication](../../ssh.md).

You can use a deploy token for [HTTP authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)
to the following endpoints:

- GitLab package registry public API.
- [Git commands](https://git-scm.com/docs/gitcredentials#_description).

You can create deploy tokens at either the project or group level:

- **Project deploy token**: Permissions apply only to the project.
- **Group deploy token**: Permissions apply to all projects in the group.

By default, a deploy token does not expire. You can optionally set an expiry date when you create
it. Expiry occurs at midnight UTC on that date.

WARNING:
You cannot use new or existing deploy tokens for Git operations and package registry operations if
[external authorization](../../../administration/settings/external_authorization.md) is enabled.

## Scope

A deploy token's scope determines the actions it can perform.

| Scope                    | Description                                                                                                  |
|--------------------------|--------------------------------------------------------------------------------------------------------------|
| `read_repository`        | Read-only access to the repository using `git clone`.                                                        |
| `read_registry`          | Read-only access to the images in the project's [container registry](../../packages/container_registry/_index.md). |
| `write_registry`         | Write access (push) to the project's [container registry](../../packages/container_registry/_index.md). You need both read and write access to push images. |
| `read_package_registry`  | Read-only access to the project's package registry.                                                          |
| `write_package_registry` | Write access to the project's package registry.                                                              |

## GitLab deploy token

> - Support for `gitlab-deploy-token` at the group level [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214014) in GitLab 15.1 [with a flag](../../../administration/feature_flags.md) named `ci_variable_for_group_gitlab_deploy_token`. Enabled by default.
> - [Feature flag `ci_variable_for_group_gitlab_deploy_token`](https://gitlab.com/gitlab-org/gitlab/-/issues/363621) removed in GitLab 15.4.

A GitLab deploy token is a special type of deploy token. If you create a deploy token named
`gitlab-deploy-token`, the deploy token is automatically exposed to project CI/CD jobs as variables:

- `CI_DEPLOY_USER`: Username
- `CI_DEPLOY_PASSWORD`: Token

For example, to use a GitLab token to sign in to your GitLab container registry:

```shell
echo "$CI_DEPLOY_PASSWORD" | docker login $CI_REGISTRY -u $CI_DEPLOY_USER --password-stdin
```

NOTE:
In GitLab 15.0 and earlier, the special handling for the `gitlab-deploy-token` deploy token does not
work for group deploy tokens. To make a group deploy token available for CI/CD jobs, set the
`CI_DEPLOY_USER` and `CI_DEPLOY_PASSWORD` CI/CD variables in **Settings > CI/CD > Variables** to the
name and token of the group deploy token.

When `gitlab-deploy-token` is defined in a group, the `CI_DEPLOY_USER` and `CI_DEPLOY_PASSWORD`
CI/CD variables are available only to immediate child projects of the group.

### GitLab deploy token security

GitLab deploy tokens are long-lived, making them attractive for attackers.

To prevent leaking the deploy token, you should also configure your
[runners](../../../ci/runners/_index.md) to be secure:

- Avoid using Docker `privileged` mode if the machines are re-used.
- Avoid using the [`shell` executor](https://docs.gitlab.com/runner/executors/shell.html) when jobs
  run on the same machine.

An insecure GitLab Runner configuration increases the risk that someone can steal tokens from other
jobs.

### GitLab public API

Deploy tokens can't be used with the GitLab public API. However, you can use deploy tokens with some
endpoints, such as those from the package registry. You can tell an endpoint belongs to the package registry because the URL has the string `packages/<format>`. For example: `https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/0.0.1/file.txt`. For more information, see
[Authenticate with the registry](../../packages/package_registry/_index.md#authenticate-with-the-registry).

## Create a deploy token

Create a deploy token to automate deployment tasks that can run independently of a user account.

Prerequisites:

- To create a group deploy token, you must have the Owner role for the group.
- To create a project deploy token, you must have at least the Maintainer role for the project.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Repository**.
1. Expand **Deploy tokens**.
1. Select **Add token**.
1. Complete the fields, and select the desired [scopes](#scope).
1. Select **Create deploy token**.

Record the deploy token's values. After you leave or refresh the page, **you cannot access it
again**.

## Revoke a deploy token

Revoke a token when it's no longer required.

Prerequisites:

- To revoke a group deploy token, you must have the Owner role for the group.
- To revoke a project deploy token, you must have at least the Maintainer role for the project.

To revoke a deploy token:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Repository**.
1. Expand **Deploy tokens**.
1. In the **Active Deploy Tokens** section, by the token you want to revoke, select **Revoke**.

## Clone a repository

You can use a deploy token to clone a repository.

Prerequisites:

- A deploy token with the `read_repository` scope.

Example of using a deploy token to clone a repository:

```shell
git clone https://<username>:<deploy_token>@gitlab.example.com/tanuki/awesome_project.git
```

## Pull images from a container registry

You can use a deploy token to pull images from a container registry.

Prerequisites:

- A deploy token with the `read_registry` scope.

Example of using a deploy token to pull images from a container registry:

```shell
echo "$DEPLOY_TOKEN" | docker login -u <username> --password-stdin registry.example.com
docker pull $CONTAINER_TEST_IMAGE
```

## Push images to a container registry

You can use a deploy token to push images to a container registry.

Prerequisites:

- A deploy token with the `read_registry` and `write_registry` scope.

Example of using a deploy token to push an image to a container registry:

```shell
echo "$DEPLOY_TOKEN" | docker login -u <username> --password-stdin registry.example.com
docker push $CONTAINER_TEST_IMAGE
```

## Pull packages from a package registry

You can use a deploy token to pull packages from a package registry.

Prerequisites:

- A deploy token with the `read_package_registry` scope.

For the [package type of your choice](../../packages/_index.md), follow the authentication
instructions for deploy tokens.

Example of installing a NuGet package from a GitLab registry:

```shell
nuget source Add -Name GitLab -Source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" -UserName <username> -Password <deploy_token>
nuget install mypkg.nupkg
```

## Push packages to a package registry

You can use a deploy token to push packages to a GitLab package registry.

Prerequisites:

- A deploy token with the `write_package_registry` scope.

For the [package type of your choice](../../packages/_index.md), follow the authentication
instructions for deploy tokens.

Example of publishing a NuGet package to a package registry:

```shell
nuget source Add -Name GitLab -Source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" -UserName <username> -Password <deploy_token>
nuget push mypkg.nupkg -Source GitLab
```

## Pull images from the dependency proxy

You can use a deploy token to pull images from the dependency proxy.

Prerequisites:

- A deploy token with `read_registry` and `write_registry` scopes.

Follow the dependency proxy [authentication instructions](../../packages/dependency_proxy/_index.md).
