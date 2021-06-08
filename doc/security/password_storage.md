---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Password storage **(FREE)**

GitLab stores user passwords in a hashed format to prevent passwords from being
stored as plain text.

GitLab uses the [Devise](https://github.com/heartcombo/devise) authentication
library to hash user passwords. Created password hashes have these attributes:

- **Hashing**: The [`bcrypt`](https://en.wikipedia.org/wiki/Bcrypt) hashing
  function is used to generate the hash of the provided password. This is a
  strong, industry-standard cryptographic hashing function.
- **Stretching**: Password hashes are [stretched](https://en.wikipedia.org/wiki/Key_stretching)
  to harden against brute-force attacks. By default, GitLab uses a stretching
  factor of 10.
- **Salting**: A [cryptographic salt](https://en.wikipedia.org/wiki/Salt_(cryptography))
  is added to each password to harden against pre-computed hash and dictionary
  attacks. To increase security, each salt is randomly generated for each
  password, with no two passwords sharing a salt.
