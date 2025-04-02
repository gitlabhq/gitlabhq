---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Application secrets
---

GitLab must be able to access various secrets such as access tokens and other credentials to function.
These secrets are encrypted and stored at rest and may be found in different data stores depending on use.
Use this guide to understand how different kinds of secrets are stored and managed.

## Application secrets and operational secrets

Broadly speaking, there are two classes of secrets:

<!-- vale gitlab_base.SubstitutionWarning = NO -->

1. **Application secrets.** The GitLab application uses these to implement a particular feature or function.
   An example would be access tokens or private keys to create cryptographic signatures. We store
   these secrets in the database in encrypted columns.
   See [Secure Coding Guidelines: At rest](secure_coding_guidelines.md#at-rest).
1. **Operational secrets.** Used to read and store other secrets or bootstrap the application. For this reason,
   they cannot be stored in the database.
   These secrets are stored as [Rails credentials](https://guides.rubyonrails.org/security.html#environmental-security)
   in the `config/secrets.yml` file:

   - Directly for self-compiled installations.
   - Through an installer like Omnibus or Helm (where actual secrets can be stored in an external secrets container like
     [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/) or [Vault](https://www.vaultproject.io/)).

<!-- vale gitlab_base.SubstitutionWarning = YES -->

## Application secrets

Application secrets should be stored in PostgreSQL using `ActiveRecord::Encryption`:

```ruby
class MyModel < ApplicationRecord
  encrypts :my_secret
end
```

{{< alert type="note" >}}
Until recently, we used `attr_encrypted` instead of `ActiveRecord::Encryption`. We are in the process of
migrating all columns to use the new Rails-native encryption framework (see [epic 15420](https://gitlab.com/groups/gitlab-org/-/epics/15420)).
{{< /alert >}}

{{< alert type="note" >}}
Despite there being precedent, application secrets should not be stored as an `ApplicationSetting`.
This can lead to the entire application malfunctioning if this secret fails to decode. To reduce
coupling to other features, isolate secrets into dedicated tables.
{{< /alert >}}

{{< alert type="note" >}}
In some cases, it can be undesirable to store secrets in the database. For example, if the secret is needed
to bootstrap the Rails application, it may have to access the database in an initializer, which can lead to
initialization races as the database connection itself may not yet be ready. In this case, store the secret
as an operational secret instead.
{{< /alert >}}

## Operational secrets

We maintain a number of operational secrets in `config/secrets.yml`, primarily to manage other secrets. Historically, GitLab
used this approach for all secrets, including application secrets, but has meanwhile moved most of these into postgres.
The only exception is `openid_connect_signing_key` since it needs to be accessed from a Rails initializer before
the database may be ready.

### Secret entries

|Entry                             |Description                                                        |
|---                               |---                                                                |
| `secret_key_base`                | The base key to be used for generating a various secrets          |
| `otp_key_base`                   | The base key for One Time Passwords, described in [User management](../administration/raketasks/user_management.md#rotate-two-factor-authentication-encryption-key)              |
| `db_key_base`                    | The base key to encrypt the data for `attr_encrypted` columns     |
| `openid_connect_signing_key`     | The signing key for OpenID Connect                                |
| `encrypted_settings_key_base`    | The base key to encrypt settings files with                       |
| `active_record_encryption_primary_key` | The base key to non-deterministically-encrypt data for `ActiveRecord::Encryption` encrypted columns |
| `active_record_encryption_deterministic_key` | The base key to deterministically-encrypt data for `ActiveRecord::Encryption` encrypted columns |
| `active_record_encryption_key_derivation_salt` | The derivation salt to encrypt data for `ActiveRecord::Encryption` encrypted columns |

### Where the secrets are stored

|Installation type                  |Location                                                          |
|---                                |---                                                               |
| Linux package                     |[`/etc/gitlab/gitlab-secrets.json`](https://docs.gitlab.com/omnibus/settings/backups.html#backup-and-restore-omnibus-gitlab-configuration) |
| Cloud Native GitLab Charts        |[Kubernetes Secrets](https://docs.gitlab.com/charts/installation/secrets.html#gitlab-rails-secret) |
| Self-compiled                     |`<path-to-gitlab-rails>/config/secrets.yml` (Automatically generated by [`config/initializers/01_secret_token.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/01_secret_token.rb)) |

### Warning: Before you add a new secret to application secrets

#### Add support to Omnibus GitLab and the Cloud Native GitLab charts

Before you add a new secret to
[`config/initializers/01_secret_token.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/01_secret_token.rb),
make sure you also update Omnibus GitLab and the Cloud Native GitLab charts, or the update will fail.
Both installation methods are responsible for writing the `config/secrets.yml` file.
If if they don't know about a secret, Rails attempts to write to the file, and fails because it doesn't
have write access.

**Examples**

- [Change for self-compiled installation](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175154)
- [Change for Omnibus GitLab installation](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8026)
- [Change for Cloud Native installation](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3988)

#### Populate the secrets in live environments

Additionally, in case you need the secret to have the same value on all nodes (which is usually the case),
you need to make sure
[it's configured for all live environments (GitLab.com, staging, pre)](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab-external-secrets/values/values.yaml.gotmpl)
prior to changing this file.

#### Document the new secrets

1. Add the new secrets to this documentation file.
1. Mention the new secrets in the next release upgrade notes.
   For instance, for the 17.8 release, the notes would go in `data/release_posts/17_8/17-8-upgrade.yml` and contain something like the following:

   ```yaml
   ---
   upgrades:
     - reporter: <your username>  # item author username
       description: |
         In Gitlab 17.8, three new secrets have been added to support the upcoming encryption framework:
         - `active_record_encryption_primary_key`
         - `active_record_encryption_deterministic_key`
         - `active_record_encryption_key_derivation_salt`

         **If you have a multi-node configuration, you should ensure these secrets are the same on all nodes.** Otherwise, the application will automatically generate the missing secrets.

         If you use the [GitLab helm chart](https://docs.gitlab.com/charts/) and disabled the [shared-secrets chart](https://docs.gitlab.com/charts/charts/shared-secrets/), you will need to [manually  create these secrets](https://docs.gitlab.com/charts/installation/secrets.html#gitlab-rails-secret).
   ```

1. Mention the new secrets in the next Cloud Native GitLab charts upgrade notes.
   For instance, for 8.8, you should document the new secrets in <https://docs.gitlab.com/charts/releases/8_0.html>.

## Further iteration

We may either deprecate or remove this automatic secret generation performed by `config/initializers/01_secret_token.rb` in the future.
See [issue #222690](https://gitlab.com/gitlab-org/gitlab/-/issues/222690) for more information.
