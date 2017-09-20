# User account

When logged into their GitLab account, users can customize their
experience according to the best approach to their cases.

## Username

Your `username` is a unique [`namespace`](../group/index.md#namespaces)
related to your user ID.

### Changing your username

You can change your `username` from your
[profile settings](#profile-settings).

> **Note:** If you want to retain ownership over the original namespace and
protect the URL redirects, then instead of changing your username, you can
create a new group and transfer projects to it.
Alternatively, you can follow [this detailed procedure from the GitLab Team Handbook](https://about.gitlab.com/handbook/tools-and-tips/#how-to-change-your-username-at-gitlabcom).

Changing your username can have unintended side effects.

* Existing web URLs for the user and anything under it (i.e. projects) will
redirect to the new URLs
* Existing Git remote URLs for projects under the user will no longer work, but
Git responses will show an error with the new remote URL
* The original namespace can be claimed again by any group or user, which will
destroy any web redirects and Git remote warnings

> It is currently not possible to rename a namespace if it contains a
project with container registry tags, because the project cannot be moved.

## User profile

Your profile is available from the up-right corner menu bar (user's avatar) > **Profile**,
or from `https://example.gitlab.com/username`.

On your profile page, you will see the following information:

- Personal information
- Activity stream: see your activity streamline and the history of your contributions
- Groups: [groups](../group/index.md) you're a member of
- Contributed projects: [projects](../project/index.md) you contributed to
- Personal projects: your personal projects (respecting the project's visibility level)
- Snippets: your personal code [snippets](../snippets.md#personal-snippets)

## Profile settings

You can edit your account settings by navigating from the up-right corner menu bar
(user's avatar) > **Settings**, or visiting `https://example.gitlab.com/profile`.

From there, you can:

- Update your personal information
- Manage [private tokens](../../api/README.md#private-tokens), email tokens, [2FA](account/two_factor_authentication.md)
- Change your username and [delete your account](account/delete_account.md)
- Manage applications that can
[use GitLab as an OAuth provider](../../integration/oauth_provider.md#introduction-to-oauth)
- Manage [personal access tokens](personal_access_tokens.md) to access your account via API and authorized applications
- Add and delete emails linked to your account
- Manage [SSH keys](../../ssh/README.md#ssh) to access your account via SSH
- Manage your [preferences](preferences.md#syntax-highlighting-theme)
to customize your own GitLab experience
- Acess your audit log, a security log of important events involving your account
