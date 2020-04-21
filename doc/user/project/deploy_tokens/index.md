# Deploy Tokens

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17894) in GitLab 10.7.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/issues/199370) from **Settings > Repository** in GitLab 12.9.
> - [Added `write_registry` scope](https://gitlab.com/gitlab-org/gitlab/-/issues/22743) in GitLab 12.10.

Deploy tokens allow you to download (`git clone`) or push and pull the container registry images of a project without having a user and a password.

Deploy tokens can be managed by [maintainers only](../../permissions.md).

If you have a key pair, you might want to use [deploy keys](../../../ssh/README.md#deploy-keys) instead.

## Creating a Deploy Token

You can create as many deploy tokens as you like from the settings of your project. Alternatively, you can also create [group-scoped deploy tokens](#group-deploy-token).

1. Log in to your GitLab account.
1. Go to the project (or group) you want to create Deploy Tokens for.
1. Go to **{settings}** **Settings** > **CI / CD**.
1. Click on "Expand" on **Deploy Tokens** section.
1. Choose a name, expiry date (optional), and username (optional) for the token.
1. Choose the [desired scopes](#limiting-scopes-of-a-deploy-token).
1. Click on **Create deploy token**.
1. Save the deploy token somewhere safe. Once you leave or refresh
   the page, **you won't be able to access it again**.

![Personal access tokens page](img/deploy_tokens.png)

## Deploy token expiration

Deploy tokens expire on the date you define, at midnight UTC.

## Revoking a deploy token

At any time, you can revoke any deploy token by just clicking the
respective **Revoke** button under the 'Active deploy tokens' area.

## Limiting scopes of a deploy token

Deploy tokens can be created with two different scopes that allow various
actions that a given token can perform. The available scopes are depicted in
the following table.

| Scope | Description |
| ----- | ----------- |
| `read_repository` | Allows read-access to the repository through `git clone` |
| `read_registry` | Allows read-access to [container registry](../../packages/container_registry/index.md) images if a project is private and authorization is required. |
| `write_registry` | Allows write-access (push) to [container registry](../../packages/container_registry/index.md). |

## Deploy token custom username

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/29639) in GitLab 12.1.

The default username format is `gitlab+deploy-token-#{n}`. Some tools or platforms may not support this format,
in such case you can specify custom username to be used when creating the deploy token.

## Usage

### Git clone a repository

To download a repository using a Deploy Token, you just need to:

1. Create a Deploy Token with `read_repository` as a scope.
1. Take note of your `username` and `token`.
1. `git clone` the project using the Deploy Token:

   ```shell
   git clone https://<username>:<deploy_token>@gitlab.example.com/tanuki/awesome_project.git
   ```

Replace `<username>` and `<deploy_token>` with the proper values.

### Read Container Registry images

To read the container registry images, you'll need to:

1. Create a Deploy Token with `read_registry` as a scope.
1. Take note of your `username` and `token`.
1. Log in to GitLab’s Container Registry using the deploy token:

```shell
docker login -u <username> -p <deploy_token> registry.example.com
```

Just replace `<username>` and `<deploy_token>` with the proper values. Then you can simply
pull images from your Container Registry.

### Push Container Registry images

To push the container registry images, you'll need to:

1. Create a Deploy Token with `write_registry` as a scope.
1. Take note of your `username` and `token`.
1. Log in to GitLab’s Container Registry using the deploy token:

   ```shell
   docker login -u <username> -p <deploy_token> registry.example.com
   ```

Just replace `<username>` and `<deploy_token>` with the proper values. Then you can simply
push images to your Container Registry.

### Group Deploy Token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/21765) in GitLab 12.9.

A deploy token created at the group level can be used across all projects that
belong either to the specific group or to one of its subgroups.

To use a group deploy token:

1. [Create](#creating-a-deploy-token) a deploy token for a group.
1. Use it the same way you use a project deploy token when
   [cloning a repository](#git-clone-a-repository).

The scopes applied to a group deploy token (such as `read_repository`) will
apply consistently when cloning the repository of related projects.

### GitLab Deploy Token

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18414) in GitLab 10.8.

There's a special case when it comes to Deploy Tokens. If a user creates one
named `gitlab-deploy-token`, the username and token of the Deploy Token will be
automatically exposed to the CI/CD jobs as environment variables: `CI_DEPLOY_USER` and
`CI_DEPLOY_PASSWORD`, respectively. With the GitLab Deploy Token, the
`read_registry` and `write_registry` scopes are implied.

After you create the token, you can login to the Container Registry using
those variables:

```shell
docker login -u $CI_DEPLOY_USER -p $CI_DEPLOY_PASSWORD $CI_REGISTRY
```
