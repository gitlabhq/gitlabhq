# Enforce accepting Terms of Service

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18570)
> in [GitLab Core](https://about.gitlab.com/pricing/) 10.8

## Configuration

When it is required for all users of the GitLab instance to accept the
Terms of Service, this can be configured by an admin on the settings
page:

![Enable enforcing Terms of Service](img/enforce_terms.png).

The terms itself can be entered using Markdown. For each update to the
terms, a new version is stored. When a user accepts or declines the
terms, GitLab will keep track of which version they accepted or
declined.

When an admin enables this feature, they will automattically be
directed to the page to accept the terms themselves. After they
accept, they will be directed back to the settings page.

## New registrations

When this feature is enabled, a checkbox will be available in the
sign-up form.

![Sign up form](img/sign_up_terms.png)

This checkbox will be required during sign up.

Users can review the terms entered in the admin panel before
accepting. The page will be opened in a new window so they can
continue their registration afterwards.

## Accepting terms

When this feature was enabled, the users that have not accepted the
terms of service will be presented with a screen where they can either
accept or decline the terms.

![Respond to terms](img/respond_to_terms.png)

When the user accepts the terms, they will be directed to where they
were going. After a sign-in or sign-up this will most likely be the
dashboard.

When the user was already logged in when the feature was turned on,
they will be asked to accept the terms on their next interaction.

When a user declines the terms, they will be signed out.
