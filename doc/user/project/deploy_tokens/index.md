---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Deploy tokens **(FREE)**

> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/199370) from **Settings > Repository** to **Settings > CI/CD** in GitLab 12.9.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/22743) `write_registry` scope in GitLab 12.10.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29280) from **Settings > CI/CD** to **Settings > Repository** in GitLab 12.10.1.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/213566) package registry scopes in GitLab 13.0.

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

You can use a deploy token for [HTTP authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)
to the following endpoints:

- GitLab Package Registry public API.
- [Git commands](https://git-scm.com/docs/gitcredentials#_description).

You can create deploy tokens at either the project or group level:

- **Project deploy token**: Permissions apply only to the project.
- **Group deploy token**: Permissions apply to all projects in the group.

By default, a deploy token does not expire. You can optionally set an expiry date when you create
it. Expiry occurs at midnight UTC on that date.

## Scope

A deploy token's scope determines the actions it can perform.

| Scope                    | Description                                                                                                  |
|--------------------------|--------------------------------------------------------------------------------------------------------------|
| `read_repository`        | Read-only access to the repository using `git clone`.                                                        |
| `read_registry`          | Read-only access to the images in the project's [container registry](../../packages/container_registry/index.md). |
| `write_registry`         | Write access (push) to the project's [container registry](../../packages/container_registry/index.md).       |
| `read_package_registry`  | Read-only access to the project's package registry.                                                          |
| `write_package_registry` | Write access to the project's package registry.                                                              |

## GitLab deploy token

> - Support for `gitlab-deploy-token` at the group level [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214014) in GitLab 15.1 [with a flag](../../../administration/feature_flags.md) named `ci_variable_for_group_gitlab_deploy_token`. Enabled by default.
> - [Feature flag `ci_variable_for_group_gitlab_deploy_token`](https://gitlab.com/gitlab-org/gitlab/-/issues/363621) removed in GitLab 15.4.

A GitLab deploy token is a special type of deploy token. If you create a deploy token named
`gitlab-deploy-token`, the deploy token is automatically exposed to the CI/CD jobs as variables, for
use in a CI/CD pipeline:

- `CI_DEPLOY_USER`: Username
- `CI_DEPLOY_PASSWORD`: Token

For example, to use a GitLab token to log in to your GitLab container registry:

```shell
docker login -u $CI_DEPLOY_USER -p $CI_DEPLOY_PASSWORD $CI_REGISTRY
```

NOTE:
In GitLab 15.0 and earlier, the special handling for the `gitlab-deploy-token` deploy token does not
work for group deploy tokens. To make a group deploy token available for CI/CD jobs, set the
`CI_DEPLOY_USER` and `CI_DEPLOY_PASSWORD` CI/CD variables in **Settings > CI/CD > Variables** to the
name and token of the group deploy token.

### GitLab public API

Deploy tokens can't be used with the GitLab public API. However, you can use deploy tokens with some
endpoints, such as those from the Package Registry. For more information, see
[Authenticate with the registry](../../packages/package_registry/index.md#authenticate-with-the-registry).

## Creating a Deploy token

You can create as many deploy tokens as you need from the settings of your
project. Alternatively, you can also create [group-scoped deploy tokens](#group-deploy-token).

1. Sign in to your GitLab account.
1. On the top bar, select **Main menu**, and:
   - For a project, select ***Projects** and find your project.
   - For a group, select **Groups** and find your group.
1. On the left sidebar, select **Settings > Repository**.
1. Expand **Deploy tokens**.
1. Choose a name, and optionally, an expiration date and username for the token.
1. Choose the [desired scopes](#scope).
1. Select **Create deploy token**.

Save the deploy token somewhere safe. After you leave or refresh
the page, **you can't access it again**.

![Personal access tokens page](img/deploy_tokens_ui.png)

## Revoking a deploy token

To revoke a deploy token:

1. On the top bar, select **Main menu**, and:
   - For a project, select ***Projects** and find your project.
   - For a group, select **Groups** and find your group.
1. On the left sidebar, select **Settings > Repository**.
1. Expand **Deploy tokens**.
1. In the **Active Deploy Tokens** section, by the token you want to revoke, select **Revoke**.

## Usage

### Git clone a repository

To download a repository using a deploy token:

1. Create a deploy token with `read_repository` as a scope.
1. Take note of your `username` and `token`.
1. `git clone` the project using the deploy token:

   ```shell
   git clone https://<username>:<deploy_token>@gitlab.example.com/tanuki/awesome_project.git
   ```

Replace `<username>` and `<deploy_token>` with the proper values.

### Read Container Registry images

To read the container registry images, you must:

1. Create a deploy token with `read_registry` as a scope.
1. Take note of your `username` and `token`.
1. Sign in to the GitLab Container Registry using the deploy token:

```shell
docker login -u <username> -p <deploy_token> registry.example.com
```

Replace `<username>` and `<deploy_token>` with the proper values. You can now
pull images from your Container Registry.

### Push Container Registry images

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22743) in GitLab 12.10.

To push the container registry images, you must:

1. Create a deploy token with `write_registry` as a scope.
1. Take note of your `username` and `token`.
1. Sign in to the GitLab Container Registry using the deploy token:

   ```shell
   docker login -u <username> -p <deploy_token> registry.example.com
   ```

Replace `<username>` and `<deploy_token>` with the proper values. You can now
push images to your Container Registry.

### Read or pull packages

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213566) in GitLab 13.0.

To pull packages in the GitLab package registry, you must:

1. Create a deploy token with `read_package_registry` as a scope.
1. Take note of your `username` and `token`.
1. For the [package type of your choice](../../packages/index.md), follow the
   authentication instructions for deploy tokens.

Example request publishing a NuGet package using a deploy token:

```shell
nuget source Add -Name GitLab -Source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" -UserName deploy-token-username -Password 12345678asdf

nuget push mypkg.nupkg -Source GitLab
```

### Push or upload packages

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213566) in GitLab 13.0.

To upload packages in the GitLab package registry, you must:

1. Create a deploy token with `write_package_registry` as a scope.
1. Take note of your `username` and `token`.
1. For the [package type of your choice](../../packages/index.md), follow the
   authentication instructions for deploy tokens.

### Group deploy token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21765) in GitLab 12.9.

A deploy token created at the group level can be used across all projects that
belong either to the specific group or to one of its subgroups.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Group Deploy Tokens](https://youtu.be/8kxTJvaD9ks).

The Group deploy tokens UI is now accessible under **Settings > Repository**,
not **Settings > CI/CD** as indicated in the video.

To use a group deploy token:

1. [Create](#creating-a-deploy-token) a deploy token for a group.
1. Use it the same way you use a project deploy token when
   [cloning a repository](#git-clone-a-repository).

The scopes applied to a group deploy token (such as `read_repository`)
apply consistently when cloning the repository of related projects.

### Pull images from the Dependency Proxy

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/280586) in GitLab 14.2.

To pull images from the Dependency Proxy, you must:

1. Create a group deploy token with both `read_registry` and `write_registry` scopes.
1. Take note of your `username` and `token`.
1. Follow the Dependency Proxy [authentication instructions](../../packages/dependency_proxy/index.md).

## Troubleshooting

### Group deploy tokens and LFS

A bug
[prevents Group Deploy Tokens from cloning LFS objects](https://gitlab.com/gitlab-org/gitlab/-/issues/235398).
If you receive `404 Not Found` errors and this error,
use a Project Deploy Token to work around the bug:

```plaintext
api error: Repository or object not found:
https://<URL-with-token>.git/info/lfs/objects/batch
Check that it exists and that you have proper access to it
```
