---
type: reference
---

# Password Storage

GitLab stores user passwords in a hashed format, to prevent passwords from being visible.

GitLab uses the [Devise](https://github.com/plataformatec/devise) authentication library, which handles the hashing of user passwords. Password hashes are created with the following attributes:

- **Hashing**: the [bcrypt](https://en.wikipedia.org/wiki/Bcrypt) hashing function is used to generate the hash of the provided password. This is a strong, industry-standard cryptographic hashing function.
- **Stretching**: Password hashes are [stretched](https://en.wikipedia.org/wiki/Key_stretching) to harden against brute-force attacks. GitLab uses a stretching factor of 10 by default.
- **Salting**: A [cryptographic salt](https://en.wikipedia.org/wiki/Salt_(cryptography)) is added to each password to harden against pre-computed hash and dictionary attacks. Each salt is randomly generated for each password, so that no two passwords share a salt to further increase security.
