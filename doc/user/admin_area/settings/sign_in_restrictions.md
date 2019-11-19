---
type: reference
---

# Sign-in restrictions **(CORE ONLY)**

You can use sign-in restrictions to limit the authentication with password
for web interface and Git over HTTP(S), two-factor authentication enforcing, as well as
as configuring the home page URL and after sign-out path.

## Password authentication enabled

You can restrict the password authentication for web interface and Git over HTTP(S):

- **Web interface**: When this feature is disabled, an [external authentication provider](../../../administration/auth/README.md) must be used.
- **Git over HTTP(S)**: When this feature is disabled, a [Personal Access Token](../../profile/personal_access_tokens.md) must be used to authenticate.

## Two-factor authentication

When this feature enabled, all users will have to use the [two-factor authentication](../../profile/account/two_factor_authentication.md).

Once the two-factor authentication is configured as mandatory, the users will be allowed
to skip forced configuration of two-factor authentication for the configurable grace
period in hours.

![Two-factor grace period](img/two_factor_grace_period.png)

## Sign-in information

All users that are not logged-in will be redirected to the page represented by the configured
"Home page URL" if value is not empty.

All users will be redirect to the page represented by the configured "After sign out path"
after sign out if value is not empty.

If a "Sign in text" in Markdown format is provided, then every user will be presented with
this message after logging-in.

## Settings

To access this feature:

1. Navigate to the **Settings > General** in the Admin area.
1. Expand the **Sign-in restrictions** section.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
