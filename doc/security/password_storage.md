---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Password storage **(FREE)**

> PBKDF2 and SHA512 [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360658) in GitLab 15.2 [with flags](../administration/feature_flags.md) named `pbkdf2_password_encryption` and `pbkdf2_password_encryption_write`. Disabled by default.

GitLab stores user passwords in a hashed format to prevent passwords from being
stored as plain text.

GitLab uses the [Devise](https://github.com/heartcombo/devise) authentication
library to hash user passwords. Created password hashes have these attributes:

- **Hashing**:
  - **BCrypt**: By default, the [`bcrypt`](https://en.wikipedia.org/wiki/Bcrypt) hashing
    function is used to generate the hash of the provided password. This is a
    strong, industry-standard cryptographic hashing function.
  - **PBKDF2 and SHA512**: Starting in GitLab 15.2, PBKDF2 and SHA512 are supported
    behind the following feature flags (disabled by default):
    - `pbkdf2_password_encryption` - Enables reading and comparison of PBKDF2 + SHA512
      hashed passwords and supports fallback for BCrypt hashed passwords.
    - `pbkdf2_password_encryption_write` - Enables new passwords to be saved
      using PBKDF2 and SHA512, and existing BCrypt passwords to be migrated when users sign in.

    FLAG:
    On self-managed GitLab, by default this feature is not available. To make it available,
    ask an administrator to [enable the feature flags](../administration/feature_flags.md) named `pbkdf2_password_encryption` and `pbkdf2_password_encryption_write`.

- **Stretching**: Password hashes are [stretched](https://en.wikipedia.org/wiki/Key_stretching)
  to harden against brute-force attacks. By default, GitLab uses a stretching
  factor of 10 for BCrypt and 20,000 for PBKDF2 + SHA512.
- **Salting**: A [cryptographic salt](https://en.wikipedia.org/wiki/Salt_(cryptography))
  is added to each password to harden against pre-computed hash and dictionary
  attacks. To increase security, each salt is randomly generated for each
  password, with no two passwords sharing a salt.
