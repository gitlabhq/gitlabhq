---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: 'Using the `TokenAuthenticatable` concern'
---

The `TokenAuthenticatable` module is a concern that provides token-based authentication functionality for `ActiveRecord` models.
It allows you to define authentication tokens for your models.

## Overview

This module provides a flexible way to add token-based authentication to your models.

It supports three storage strategies:

- `insecure`: the token is stored as-is (not encrypted) in the database
- `digest`: the `SHA256` digests of the token is stored in the database
- `encrypted`: the token is stored encrypted in the database using the AES 256 GCM algorithm

It also supports several options for each storage strategies.

## Usage

To define a `token_field` attribute in your model, include the module and call `add_authentication_token_field`:

```ruby
class User < ApplicationRecord
  include TokenAuthenticatable

  add_authentication_token_field :token_field, encrypted: :required
end
```

### Storage strategies

- `encrypted: :required`: Stores the encrypted token in the `token_field_encrypted` column.
  The `token_field_encrypted` column needs to exist. We strongly encourage to use this strategy.
- `encrypted: :migrating`: Stores the encrypted and plaintext tokens respectively in `token_field_encrypted` and `token_field`.
  Always reads the plaintext token. This should be used while an attribute is transitioning to be encrypted.
  Both `token_field` and `token_field_encrypted` columns need to exist.
- `encrypted: :optional`: Stores the encrypted token in the `token_field_encrypted` column.
  Reads from `token_field_encrypted` first and fallbacks to `token_field`.
  Nullifies the plaintext token in the `token_field` column when writing the encrypted token.
  Both `token_field` and `token_field_encrypted` columns need to exist.
- `digest: true`: Stores the token's digest in the database.
  The `token_field_digest` column needs to exist.

NOTE:
By default, tokens are stored as-is (not encrypted).

### Other options

- `unique: false`: Doesn't enforce token uniqueness and disables the generation of `find_by_token_field` (where `token_field` is the attribute name). Default is `true`.
- `format_with_prefix: :compute_token_prefix`: Allows to define a prefix for the token. The `#compute_token_prefix` method needs to return a `String`. Default is no prefix.
- `expires_at: :compute_token_expiration_time`: Allows to define a time when the token should expire.
  The `#compute_token_expiration_time` method needs to return a `Time` object. Default is no expiration.
- `token_generator:` A proc that returns a token. If absent, a random token is generated using `Devise.friendly_token`.
- `routable_token:`: A hash allowing to define "routable" parts that should be encoded in the token.
  This follows the [Routable Tokens design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/routable_tokens/#proposal).
  Supported keys are:
  - `if:`: a proc receiving the token owner record. The proc usually has a feature flag check, and/or other checks.
    If the proc returns `false`, a random token is generated using `Devise.friendly_token`.
  - `payload:`: A `{ key => proc }` hash with allowed keys `c`, `o`, `g`, `p`,`u` which
    [complies with the specification](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/routable_tokens/#meaning-of-fields).
    See an example in the [Routable Tokens design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/routable_tokens/#integration-into-token-authenticatable).
- `require_prefix_for_validation:` (only for the `:encrypted` strategy): Checks that the token prefix matches the expected prefix. If the prefix doesn't match, it behaves as if the token isn't set. Default `false`.

## Accessing and manipulating tokens

```ruby
user = User.new
user.token_field # Retrieves the token
user.set_token_field('new_token') # Sets a new token
user.ensure_token_field # Generates a token if not present
user.ensure_token_field! # Generates a token if not present
user.reset_token_field! # Resets the token and saves the model with #save!
user.token_field_matches?(other_token) # Securely compares the token with another
user.token_field_expires_at # Returns the expiration time
user.token_field_expired? # Checks if the token has expired
user.token_field_with_expiration # Returns a API::Support::TokenWithExpiration object, useful for API response
```
