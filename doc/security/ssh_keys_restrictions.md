---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Restrict allowed SSH key technologies and minimum length

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

`ssh-keygen` allows users to create RSA keys with as few as 768 bits, which
falls well below recommendations from certain standards groups (such as the US
NIST). Some organizations deploying GitLab need to enforce minimum key
strength, either to satisfy internal security policy or for regulatory
compliance.

Similarly, certain standards groups recommend using RSA, ECDSA, ED25519,
ECDSA_SK, or ED25519_SK over the older DSA, and administrators may need to
limit the allowed SSH key algorithms.

GitLab allows you to restrict the allowed SSH key technology as well as specify
the minimum key length for each technology:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General** .
1. Expand **Visibility and access controls**:

   ![SSH keys restriction Admin Area settings](img/ssh_keys_restrictions_settings.png)

If a restriction is imposed on any key type, users cannot upload new SSH keys that don't meet the
requirement. Any existing keys that don't meet it are disabled but not removed and users cannot
pull or push code using them.

An icon is visible to the user of a restricted key in the SSH keys section of their profile:

![Restricted SSH key icon](img/ssh_keys_restricted_key_icon.png)

Hovering over this icon tells you why the key is restricted.

## Default settings

By default, the GitLab.com and self-managed settings for the
[supported key types](../user/ssh.md#supported-ssh-key-types) are:

- RSA SSH keys are allowed.
- DSA SSH keys are forbidden ([since GitLab 11.0](https://about.gitlab.com/releases/2018/06/22/gitlab-11-0-released/#support-for-dsa-ssh-keys)).
- ECDSA SSH keys are allowed.
- ED25519 SSH keys are allowed.
- ECDSA_SK SSH keys are allowed (GitLab 14.8 and later).
- ED25519_SK SSH keys are allowed (GitLab 14.8 and later).

## Block banned or compromised keys

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24614) in GitLab 15.1 [with a flag](../administration/feature_flags.md) named `ssh_banned_key`. Enabled by default.
> - Generally available in GitLab 15.2. [Feature flag `ssh_banned_key`](https://gitlab.com/gitlab-org/gitlab/-/issues/363410) removed.

When users attempt to [add a new SSH key](../user/ssh.md#add-an-ssh-key-to-your-gitlab-account)
to GitLab accounts, the key is checked against a list of SSH keys which are known
to be compromised. Users can't add keys from this list to any GitLab account.
This restriction cannot be configured. This restriction exists because the private
keys associated with the key pair are publicly known, and can be used to access
accounts using the key pair.

If your key is disallowed by this restriction, [generate a new SSH key pair](../user/ssh.md#generate-an-ssh-key-pair)
to use instead.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
