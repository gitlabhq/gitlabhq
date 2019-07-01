# Deploy Tokens

> [Introduced][ce-17894] in GitLab 10.7.

Deploy tokens allow to download (through `git clone`), or read the container registry images of a project without the need of having a user and a password.

Please note, that the expiration of deploy tokens happens on the date you define,
at midnight UTC and that they can be only managed by [maintainers](../../permissions.md).

## Creating a Deploy Token

You can create as many deploy tokens as you like from the settings of your project:

1. Log in to your GitLab account.
1. Go to the project you want to create Deploy Tokens for.
1. Go to **Settings** > **Repository**.
1. Click on "Expand" on **Deploy Tokens** section.
1. Choose a name, expiry date (optional), and username (optional) for the token.
1. Choose the [desired scopes](#limiting-scopes-of-a-deploy-token).
1. Click on **Create deploy token**.
1. Save the deploy token somewhere safe. Once you leave or refresh
   the page, **you won't be able to access it again**.

![Personal access tokens page](img/deploy_tokens.png)

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
| `read_registry` | Allows read-access to [container registry] images if a project is private and authorization is required. |

## Deploy token custom username

> [Introduced][https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/29639] in GitLab 12.1.

The default username format is `gitlab+deploy-token-#{n}`. Some tools or platforms may not support this format,
in such case you can specify custom username to be used when creating the deploy token.

## Usage

### Git clone a repository

To download a repository using a Deploy Token, you just need to:

1. Create a Deploy Token with `read_repository` as a scope.
1. Take note of your `username` and `token`.
1. `git clone` the project using the Deploy Token:

    ```sh
    git clone http://<username>:<deploy_token>@gitlab.example.com/tanuki/awesome_project.git
    ```

Replace `<username>` and `<deploy_token>` with the proper values.

### Read Container Registry images

To read the container registry images, you'll need to:

1. Create a Deploy Token with `read_registry` as a scope.
1. Take note of your `username` and `token`.
1. Log in to GitLab’s Container Registry using the deploy token:

```sh
docker login registry.example.com -u <username> -p <deploy_token>
```

Just replace `<username>` and `<deploy_token>` with the proper values. Then you can simply
pull images from your Container Registry.

### GitLab Deploy Token

> [Introduced][ce-18414] in GitLab 10.8.

There's a special case when it comes to Deploy Tokens. If a user creates one
named `gitlab-deploy-token`, the username and token of the Deploy Token will be
automatically exposed to the CI/CD jobs as environment variables: `CI_DEPLOY_USER` and
`CI_DEPLOY_PASSWORD`, respectively. With the GitLab Deploy Token, the
`read_registry` scope is implied.

After you create the token, you can login to the Container Registry using
those variables:

```sh
docker login -u $CI_DEPLOY_USER -p $CI_DEPLOY_PASSWORD $CI_REGISTRY
```

[ce-17894]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/17894
[ce-11845]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/11845
[ce-18414]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18414
[container registry]: ../container_registry.md
