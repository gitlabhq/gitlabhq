---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
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
   See [Secure Coding Guidelines: At rest](secure_coding_guidelines/_index.md#at-rest).
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
For guidance on migrating existing `attr_encrypted` attributes, see [Migrating from `attr_encrypted` to `ActiveRecord::Encryption`](#migrating-from-attr_encrypted-to-activerecordencryption).
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

### Migrating from `attr_encrypted` to `ActiveRecord::Encryption`

We are migrating all encrypted attributes from the `attr_encrypted` gem to Rails' native `ActiveRecord::Encryption` framework. This migration ensures better security, performance, and maintainability while maintaining backward compatibility during the transition.

#### The `migrate_to_encrypts` method

The `migrate_to_encrypts` method provides a seamless migration path from `attr_encrypted` to `ActiveRecord::Encryption`. It temporarily stores data in both encryption formats during the transition period.

**Usage:**

```ruby
class MyModel < ApplicationRecord
  include Gitlab::EncryptedAttribute

  # Replace attr_encrypted with migrate_to_encrypts
  # Keep the same encryption options (mode, key, algorithm etc.) during migration
  migrate_to_encrypts :my_secret_attribute,
    mode: :per_attribute_iv,
    key: :db_key_base_truncated,
    algorithm: 'aes-256-cbc',
    insecure_mode: true
end
```

**How it works:**

1. **Dual encryption**: When an attribute is set, it's saved using both the old (`attr_encrypted`) and new (`ActiveRecord::Encryption`) formats
1. **Fallback reading**: When retrieving data, the system first checks the new format (`tmp_<attribute>` column), then falls back to the old format if needed
1. **Backward compatibility**: Existing encrypted data remains accessible throughout the migration process

**Generated methods:**

The `migrate_to_encrypts` method creates several helper methods:

- `attr_encrypted_<attribute>`: Access to the original `attr_encrypted` value
- `tmp_<attribute>`: Access to the new `ActiveRecord::Encryption` value
- `<attribute>`: Primary accessor that reads from new format first, falls back to old format

#### Migration process

The migration follows a four-milestone process to ensure zero-downtime deployment:

**Milestone M (Initial Migration):**

1. **Add temporary column**: Create a `tmp_<attribute>` column with `:jsonb` type:

   ```ruby
   class AddTmpSecretKeyToMyModel < Gitlab::Database::Migration[2.3]
     milestone '18.4'

     def change
       add_column :my_models, :tmp_secret_key, :jsonb
     end
   end
   ```

1. **Update model**: Replace `attr_encrypted` with `migrate_to_encrypts`:

   ```ruby
   class MyModel < ApplicationRecord
     include Gitlab::EncryptedAttribute

     # Before:
     # attr_encrypted :secret_key, mode: :per_attribute_iv, key: :db_key_base_truncated, algorithm: 'aes-256-cbc', insecure_mode: true

     # After:
     # Keep the same encryption options (mode, key, algorithm etc.) during migration
     migrate_to_encrypts :secret_key,
       mode: :per_attribute_iv,
       key: :db_key_base_truncated,
       algorithm: 'aes-256-cbc',
       insecure_mode: true
   end
   ```

1. **Create data migration**: Create a post-deployment migration to populate the new column:

   ```ruby
   class MigrateSecretKeyToNewEncryptionFramework < Gitlab::Database::Migration[2.3]
     milestone '18.1'
     restrict_gitlab_migration gitlab_schema: :gitlab_main

     class MigrationMyModel < MigrationRecord
       include Gitlab::EncryptedAttribute

       self.table_name = 'my_models'

       migrate_to_encrypts :secret_key,
         mode: :per_attribute_iv,
         key: :db_key_base_truncated,
         algorithm: 'aes-256-cbc',
         insecure_mode: true
     end

     def up
       MigrationMyModel.find_each do |record|
         next if record.secret_key.blank?

         record.secret_key = record.attr_encrypted_secret_key
         record.save!
       end
     end

     def down
       execute "UPDATE my_models SET tmp_secret_key = NULL"
     end
   end
   ```

   Large tables may require [batched background migrations](database/batched_background_migrations.md) instead of regular post-deployment migrations.

**Milestone M+1 (Column Rename):**

1. **Finalize migration**: Ensure the background migration has completed
1. **Rename column**: Rename the `tmp_<attribute>` column to `<attribute>`
   - [Add the regular migration](database/avoiding_downtime_in_migrations.md#add-the-regular-migration-release-m)
   - [Ignore the column](database/avoiding_downtime_in_migrations.md#ignore-the-column-release-m)
   - [Add a post-deployment migration](database/avoiding_downtime_in_migrations.md#add-a-post-deployment-migration-release-m)
1. **Update model**: Replace the `migrate_to_encrypts` method call with [the native `encrypts` Rails method](https://guides.rubyonrails.org/active_record_encryption.html#declaration-of-encrypted-attributes)
1. **Ignore old columns**: [Add `ignore_columns` for the `encrypted_<attribute>`, `encrypted_<attribute>_iv`, and `encrypted_<attribute>_salt` columns](database/avoiding_downtime_in_migrations.md#ignoring-the-column-release-m)

**Milestone M+2 (Cleanup):**

1. **Drop old columns**: [Drop the `encrypted_<attribute>`, `encrypted_<attribute>_iv`, and `encrypted_<attribute>_salt` columns](database/avoiding_downtime_in_migrations.md#dropping-the-column-release-m1)
1. **Remove ignore rule**: [Remove the `ignore_column` for `tmp_<attribute>`](database/avoiding_downtime_in_migrations.md#remove-the-ignore-rule-release-m1)

**Milestone M+3 (Final Cleanup):**

1. **Remove ignore rules**: [Remove the `ignore_columns` for the `encrypted_<attribute>`, `encrypted_<attribute>_iv`, and `encrypted_<attribute>_salt` columns](database/avoiding_downtime_in_migrations.md#removing-the-ignore-rule-release-m2)

#### Testing migrations

Use the provided shared example to test that attributes are properly encrypted with both frameworks:

```ruby
RSpec.describe MyModel, feature_category: :my_feature do
  let(:record) { build(:my_model) }

  it_behaves_like 'encrypted attribute being migrated to the new encryption framework',
    :secret_key do
    let(:record) { build(:my_model) }
  end
end
```

This shared example verifies that:

- The attribute value is correctly stored and retrieved
- Both encryption frameworks store the same decrypted value
- The encrypted values are different from the plain text (ensuring encryption is working)
- Both `attr_encrypted_<attribute>` and `tmp_<attribute>` accessors work correctly

#### Best practices

1. **Use JSONB columns**: Always use `:jsonb` type for new encrypted columns, not `:text`
1. **Maintain encryption options**: Keep the same encryption options (mode, key, algorithm) during migration
1. **Test thoroughly**: Use the provided shared examples to ensure both encryption methods work
1. **Monitor performance**: Large tables may require [batched background migrations](database/batched_background_migrations.md) instead of regular post-deployment migrations
1. **Validate data integrity**: Always verify that migrated data matches the original after migration

#### Example implementation

See the complete implementation example in:

- [MR !191926](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191926): Introduction of the `migrate_to_encrypts` method
- [MR !189940](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189940): Example usage migrating `ApplicationSetting.asset_proxy_secret_key`
- [Epic &15420](https://gitlab.com/groups/gitlab-org/-/epics/15420): Overall migration project tracking 104+ attributes

## Operational secrets

We maintain a number of operational secrets in `config/secrets.yml`, primarily to manage other secrets. Historically, GitLab
used this approach for all secrets, including application secrets, but has meanwhile moved most of these into postgres.
The only exception is `openid_connect_signing_key` since it needs to be accessed from a Rails initializer before
the database may be ready.

### Secret entries

| Entry                                          | Description |
|------------------------------------------------|-------------|
| `secret_key_base`                              | The base key to be used for generating a various secrets |
| `otp_key_base`                                 | The base key for One Time Passwords, described in [User management](../administration/raketasks/user_management.md#rotate-two-factor-authentication-encryption-key) |
| `db_key_base`                                  | The base key to encrypt the data for `attr_encrypted` columns |
| `openid_connect_signing_key`                   | The signing key for OpenID Connect |
| `encrypted_settings_key_base`                  | The base key to encrypt settings files with |
| `active_record_encryption_primary_key`         | The base key to non-deterministically-encrypt data for `ActiveRecord::Encryption` encrypted columns |
| `active_record_encryption_deterministic_key`   | The base key to deterministically-encrypt data for `ActiveRecord::Encryption` encrypted columns |
| `active_record_encryption_key_derivation_salt` | The derivation salt to encrypt data for `ActiveRecord::Encryption` encrypted columns |

### Where the secrets are stored

| Installation type          | Location |
|----------------------------|----------|
| Linux package              | [`/etc/gitlab/gitlab-secrets.json`](https://docs.gitlab.com/omnibus/settings/backups.html#backup-and-restore-omnibus-gitlab-configuration) |
| Cloud Native GitLab Charts | [Kubernetes Secrets](https://docs.gitlab.com/charts/installation/secrets.html#gitlab-rails-secret) |
| Self-compiled              | `<path-to-gitlab-rails>/config/secrets.yml` (Automatically generated by [`config/initializers/01_secret_token.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/01_secret_token.rb)) |

### Warning: Before you add a new secret to application secrets

#### Add support to Omnibus GitLab and the Cloud Native GitLab charts

Before adding a new secret to
[`config/initializers/01_secret_token.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/01_secret_token.rb),
ensure you also update the GitLab Linux package and the Cloud Native GitLab charts, or the update will fail.
Both installation methods are responsible for writing the `config/secrets.yml` file.
If if they don't know about a secret, Rails attempts to write to the file, and fails because it doesn't
have write access.

**Examples**

- [Change for self-compiled installation](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175154)
- [Change for Linux package installation](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8026)
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
