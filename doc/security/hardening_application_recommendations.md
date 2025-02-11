---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Hardening - Application Recommendations
---

For general hardening guidelines, see the [main hardening documentation](hardening.md).

You control the hardening recommendations for GitLab instances through the
web interface.

## System hooks

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **System hooks**.

In a typical hardened environment, internal information is not transmitted or stored
outside of the system. For an offline environment system, this is
implied. System hooks provide a way for local events in the environment to communicate
information outside of the environment based upon triggers.

Use cases for this capability are supported, particularly monitoring the
system through a remote system.
However, you must apply extreme caution when deploying system hooks. For hardened
systems, if they are intended to be an offline environment, a perimeter of trusted
systems allowed to communicate with each other must be enforced, so any hooks
(system, web, or file) must only communicate with those trusted systems. TLS is strongly
encouraged for communications through system hooks.

## Push rules

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Push rules**.

Ensure that the following items are selected:

- **Reject unverified users**
- **Do not allow users to remove Git tags with `git push`**
- **Check whether the commit author is a GitLab user**
- **Prevent pushing secret files**

The adjustments help limit pushes to established and authorized users.

## Deploy keys

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Deploy keys**.

Public deploy keys at are used to give read or read/write access to
**all** projects on the instance, and are intended for remote automation to access
projects. Public deploy keys should not be used in a hardened environment. If you
must use deploy keys, use project deploy keys instead. For more information, refer to
the documentation on [deploy keys](../user/project/deploy_keys/_index.md) and
[project deploy keys](../user/project/deploy_keys/_index.md#create-a-project-deploy-key).

## General

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.

Hardening adjustments can be made in 4 sections.

### Visibility and access control

The default for the following settings is **Private**:

- **Default project visibility**
- **Default snippet visibility**
- **Default group visibility**

Only users that are granted specific access to a project, snippet, or group can
access these resources. This can be adjusted later as needed or at the time of
their creation. This helps prevent accidental or malicious disclosure of information.

Depending on your security policy and posture, you might wish to set your
**Restricted visibility level** to **Public**, as this prevents user profiles
from being viewed by non-authenticated users.

In **Import sources**, select only the sources you really need.

A typical deployment has **Enabled Git access protocols** set to **Both SSH and HTTP(S)**,
however if one of the Git protocols is not in use by your users, set it to either
**Only SSH** or **Only HTTP(S)** accordingly. This helps shrink the attack surface.

For SSH key types, the following are preferred: `ED25519` (and `ED25519-SK`), `RSA`, and
`ECDSA` (and `ECDSA-SK`) in that order. `ED25519` is considered as secure as `RSA` when
`RSA` is set to 2048 bits or higher, however the `ED25519` keys are smaller and the
algorithm is much faster.

`ED25519-SK` and `ECDSA-SK` both end with `-SK` which stands for
"Security Key". The `-SK` types are compatible with FIDO/U2F standards and pertain to
usage with hardware tokens, for example YubiKeys.

`DSA` should be set to "Are forbidden". `DSA` has known flaws, and many cryptographers
are suspicious of and do not support using `ECDSA`.

If GitLab is in FIPS mode, use the following:

- If running in FIPS mode:
  - Use `RSA`, set to **Must be at least 2048 bits**.
  - Use `ECDSA` (and `ECDSA-SK`), set to **Must be at least 256 bits**.
  - Set all other key types to **Are forbidden**.
    `RSA` and `ECDSA` are both approved for FIPS use.
- If not running in FIPS mode, you must use `ED25519` and can also use `RSA`:
  - Set `ED25519` (and `ED25519-SK`) to **Must be at least 256 bits**.
  - If using `RSA`, set it to **Must be at least 2048 bits**.
  - Set all other key types to **Are forbidden**.
- If you are setting up an instance for a new group of users, define your user SSH
  key policy with the maximum bits settings for added security.

In a hardened environment RSS feeds are typically not required, and in **Feed token**,
select the **Disabled feed token** checkbox.

If all of your users are coming from specific IP addresses, use **Global-allowed IP ranges**
to specifically allow only those addresses.

For more details on **Visibility and access control**, see [visibility and access controls](../administration/settings/visibility_and_access_controls.md).
For information on SSH settings, see
[SSH keys restrictions](ssh_keys_restrictions.md).

### Account and limit

For hardening purposes, ensure the checkbox next to **Gravatar enabled** is not selected.
All extraneous communications should be curtailed, and in some environments might be
restricted. Account avatars can be manually uploaded by users.

The settings in this section are intended to help enforce a custom implementation
of your own specific standards on your users. As the various scenarios are too many
and too varied, you should review the
[account and limit settings documentation](../administration/settings/account_and_limit_settings.md)
and apply changes to enforce your own policies.

### Sign-up restrictions

Ensure open sign-up is disabled on your hardened instance. Ensure the **Sign-up enabled** checkbox is not selected.

In **Email confirmation settings**, ensure that **Hard** is selected. User verification
of their email address is now enforced before access is granted.

The **Minimum password length (number of characters)** default setting is 12 which
should be fine as long as additional authentication techniques are used. The password
should be complex, so ensure that all four of these checkboxes are selected:

- **Require numbers**
- **Require uppercase letters**
- **Require lowercase letters**
- **Require symbols**

If all of your users belong to the same organization that uses a specific domain for
email addresses, then list that domain in **Allowed domains for sign-ups**. This
prevents those with email addresses in other domains from signing up.

For more detailed information, see
[sign-up restrictions](../administration/settings/sign_up_restrictions.md).

### Sign-in restrictions

Two-factor authentication (2FA) should be enabled for all users. Ensure that the
checkbox next to **Two-factor authentication** (2FA) is selected.

The default setting for **Two-factor grace period** is 48 hours. This should be adjusted
to a much lower value, such as 8 hours.

Ensure the checkbox next to **Enable Admin Mode** is selected so that **Admin Mode** is
active. This requires users with Admin access to have to use additional
authentication in order to perform administrative tasks, enforcing additional 2FA by the user.

In **Email notification for unknown sign-ins**, ensure that **Enable email notification**
is selected. This sends an email to users when a sign-in occurs from an unrecognized location.

For more detailed information, see
[sign-in restrictions](../administration/settings/sign_in_restrictions.md).

## Integrations

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Integrations**.

In general, as long as administrators control and monitor usage, integrations
are fine in a hardened environment. Be cautious about integrations that allow
for actions from an outside system that trigger actions and processes that typically
require a level of access you would restrict or audit if performed by a local
process or authenticated user.

## Metrics and profiling

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Metrics and profiling**.

The main focus for hardening is **Usage statistics**:

- You should make sure **Enable version check** is selected. This checks to see if you
  are running the latest version of GitLab, and as new versions with new features and
  security patches come out frequently, this helps you stay up to date.

- If your environment is isolated or one where your organizational requirements
  restrict data gathering and statistics reporting to a software vendor, you may have
  to disable the **Enable service ping** feature. For more information on what data is collected to
  help you make an informed decision, see
  [service ping](../development/internal_analytics/service_ping/_index.md).

## Network

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.

For any setting that enables rate limiting, make sure it is selected. Default values
should be fine. Additionally there are numerous settings that enable access, and all
of these should be cleared.

After you've made these adjustments you can fine tune the system to meet performance
and user needs, which may require disabling and adjusting rate limits or enabling
accesses. Here are a few notables to keep in mind:

- In **Outbound requests**, if you need to open up access to a limited
  number of systems, you can limit access to just those systems by specifying
  IP address or hostname. Also in this section, make sure you've selected
  **Enforce DNS rebinding attack protection** if you're allowing any access at all.

- Under **Notes rate limit** and **Users API rate limit** you can exclude specific users
  from those limits if needed.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
