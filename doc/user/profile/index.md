# User account

When signed into their GitLab account, users can customize their
experience according to the best approach to their cases.

## Signing in

There are several ways to sign into your GitLab account.
See the [authentication topic](../../topics/authentication/index.md) for more details.

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
- Manage [2FA](account/two_factor_authentication.md)
- Change your username and [delete your account](account/delete_account.md)
- Manage applications that can
[use GitLab as an OAuth provider](../../integration/oauth_provider.md#introduction-to-oauth)
- Manage [personal access tokens](personal_access_tokens.md) to access your account via API and authorized applications
- Add and delete emails linked to your account
- Manage [SSH keys](../../ssh/README.md#ssh) to access your account via SSH
- Manage your [preferences](preferences.md#syntax-highlighting-theme)
to customize your own GitLab experience
- Access your audit log, a security log of important events involving your account

## Changing your username

Your `username` is a unique [`namespace`](../group/index.md#namespaces)
related to your user ID. Changing it can have unintended side effects, read
[how redirects will behave](../project/index.md#redirects-when-changing-repository-paths)
before proceeding.

To change your `username`:

1. Navigate to your [profile's](#profile-settings) **Settings > Account**.
1. Enter a new username under "Change username".
1. Hit **Update username**.

CAUTION: **Caution:**
It is currently not possible to change your username if it contains a
project with [Container Registry](../project/container_registry.md) tags,
because the project cannot be moved.

TIP: **Tip:**
If you want to retain ownership over the original namespace and
protect the URL redirects, then instead of changing a group's path or renaming a
username, you can create a new group and transfer projects to it.
Alternatively, you can follow [this detailed procedure from the GitLab Team Handbook](https://about.gitlab.com/handbook/tools-and-tips/#how-to-change-your-username-at-gitlabcom)
which also covers the case where you have projects hosted with
[GitLab Pages](../project/pages/index.md).

## Troubleshooting

### Why do I keep getting signed out?

When signing in to the main GitLab application, a `_gitlab_session` cookie is
set. `_gitlab_session` is cleared client-side when you close your browser
and expires after "Application settings -> Session duration (minutes)"/`session_expire_delay`
(defaults to `10080` minutes = 7 days).

When signing in to the main GitLab application, you can also check the
"Remember me" option which sets the `remember_user_token`
cookie (via [`devise`](https://github.com/plataformatec/devise)).
`remember_user_token` expires after
`config/initializers/devise.rb` -> `config.remember_for` (defaults to 2 weeks).

When the `_gitlab_session` expires or isn't available, GitLab uses the `remember_user_token`
to get you a new `_gitlab_session` and keep you signed in through browser restarts.

After your `remember_user_token` expires and your `_gitlab_session` is cleared/expired,
you will be asked to sign in again to verify your identity (which is for security reasons).
