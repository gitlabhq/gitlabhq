---
type: concepts, howto
---

# Personal access tokens

> [Introduced][ce-3749] in GitLab 8.8.

If you're unable to use [OAuth2](../../api/oauth2.md), you can use a personal access token to authenticate with the [GitLab API][api].

You can also use personal access tokens with Git to authenticate over HTTP or SSH. Personal access tokens are required when [Two-Factor Authentication (2FA)][2fa] is enabled. In both cases, you can authenticate with a token in place of your password.

Personal access tokens expire on the date you define, at midnight UTC.

For examples of how you can use a personal access token to authenticate with the API, see the following section from our [API Docs](../../api/README.md#personal-access-tokens).

## Creating a personal access token

You can create as many personal access tokens as you like from your GitLab
profile.

1. Log in to GitLab.
1. In the upper-right corner, click your avatar and select **Settings**.
1. On the  **User Settings** menu, select **Access Tokens**.
1. Choose a name and optional expiry date for the token.
1. Choose the [desired scopes](#limiting-scopes-of-a-personal-access-token).
1. Click the **Create personal access token** button.
1. Save the personal access token somewhere safe. Once you leave or refresh
   the page, you won't be able to access it again.

### Revoking a personal access token

At any time, you can revoke any personal access token by clicking the
respective **Revoke** button under the **Active Personal Access Token** area.

## Limiting scopes of a personal access token

Personal access tokens can be created with one or more scopes that allow various
actions that a given token can perform. The available scopes are depicted in
the following table.

| Scope              | Introduced in | Description |
| ------------------ | ------------- | ----------- |
| `read_user`        | [GitLab 8.15](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/5951)   | Allows access to the read-only endpoints under `/users`. Essentially, any of the `GET` requests in the [Users API][users] are allowed. |
| `api`              | [GitLab 8.15](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/5951)   | Grants complete read/write access to the API, including all groups and projects, the container registry, and the package registry. |
| `read_registry`    | [GitLab 9.3](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/11845)   | Allows to read (pull) [container registry] images if a project is private and authorization is required. |
| `sudo`             | [GitLab 10.2](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/14838)  | Allows performing API actions as any user in the system (if the authenticated user is an admin). |
| `read_repository`  | [GitLab 10.7](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/17894)  | Allows read-only access (pull) to the repository through `git clone`. |
| `write_repository` | [GitLab 11.11](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/26021) | Allows read-write access (pull, push) to the repository through `git clone`. Required for accessing Git repositories over HTTP when 2FA is enabled. |

[2fa]: ../account/two_factor_authentication.md
[api]: ../../api/README.md
[ce-3749]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/3749
[container registry]: ../packages/container_registry/index.md
[users]: ../../api/users.md
[usage]: ../../api/README.md#personal-access-tokens

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
