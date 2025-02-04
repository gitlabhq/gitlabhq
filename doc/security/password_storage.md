---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Password and OAuth token storage
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab administrators can configure how passwords and OAuth tokens are stored.

## Password storage

> - PBKDF2+SHA512 [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360658) in GitLab 15.2 [with flags](../administration/feature_flags.md) named `pbkdf2_password_encryption` and `pbkdf2_password_encryption_write`. Disabled by default.
> - Feature flags [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101691) in GitLab 15.6 and PBKDF2+SHA512 was made available to all GitLab instances running in [FIPS mode](../development/fips_gitlab.md).

GitLab stores user passwords in a hashed format to prevent passwords from being
stored as plain text.

GitLab uses the [Devise](https://github.com/heartcombo/devise) authentication
library to hash user passwords. Created password hashes have these attributes:

- **Hashing**:
  - **bcrypt**: By default, the [`bcrypt`](https://en.wikipedia.org/wiki/Bcrypt) hashing
    function is used to generate the hash of the provided password. This cryptographic hashing function is
    strong and industry-standard.
  - **PBKDF2+SHA512**: PBKDF2+SHA512 is supported:
    - In GitLab 15.2 to GitLab 15.5 when `pbkdf2_password_encryption` and `pbkdf2_password_encryption_write` [feature flags](../administration/feature_flags.md) are enabled.
    - In GitLab 15.6 and later when [FIPS mode](../development/fips_gitlab.md) is enabled (feature flags are not required).
- **Stretching**: Password hashes are [stretched](https://en.wikipedia.org/wiki/Key_stretching)
  to harden against brute-force attacks. By default, GitLab uses a stretching
  factor of 10 for bcrypt and 20,000 for PBKDF2 + SHA512.
- **Salting**: A [cryptographic salt](https://en.wikipedia.org/wiki/Salt_(cryptography))
  is added to each password to harden against pre-computed hash and dictionary
  attacks. To increase security, each salt is randomly generated for each
  password, with no two passwords sharing a salt.

## OAuth access token storage

> - PBKDF2+SHA512 introduced in GitLab 15.3 [with flag](../administration/feature_flags.md) named `hash_oauth_tokens`.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/367570) in GitLab 15.5.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/367570) in GitLab 15.6.

OAuth access tokens are stored in the database in PBKDF2+SHA512 format. As with PBKDF2+SHA512 password storage, access token values are [stretched](https://en.wikipedia.org/wiki/Key_stretching) 20,000 times to harden against brute-force attacks.
