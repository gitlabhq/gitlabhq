---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Doctor Rake tasks **(CORE ONLY)**

This is a collection of tasks to help investigate and repair
problems caused by data integrity issues.

## Verify database values can be decrypted using the current secrets

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/20069) in GitLab 13.1.

This task runs through all possible encrypted values in the
database, verifying that they are decryptable using the current
secrets file (`gitlab-secrets.json`).

Automatic resolution is not yet implemented. If you have values that
cannot be decrypted, you can follow steps to reset them, see our
docs on what to do [when the secrets file is lost](../../raketasks/backup_restore.md#when-the-secrets-file-is-lost).

This can take a very long time, depending on the size of your
database, as it checks all rows in all tables.

**Omnibus Installation**

```shell
sudo gitlab-rake gitlab:doctor:secrets
```

**Source Installation**

```shell
bundle exec rake gitlab:doctor:secrets RAILS_ENV=production
```

**Example output**

```plaintext
I, [2020-06-11T17:17:54.951815 #27148]  INFO -- : Checking encrypted values in the database
I, [2020-06-11T17:18:12.677708 #27148]  INFO -- : - ApplicationSetting failures: 0
I, [2020-06-11T17:18:12.823692 #27148]  INFO -- : - User failures: 0
[...] other models possibly containing encrypted data
I, [2020-06-11T17:18:14.938335 #27148]  INFO -- : - Group failures: 1
I, [2020-06-11T17:18:15.559162 #27148]  INFO -- : - Operations::FeatureFlagsClient failures: 0
I, [2020-06-11T17:18:15.575533 #27148]  INFO -- : - ScimOauthAccessToken failures: 0
I, [2020-06-11T17:18:15.575678 #27148]  INFO -- : Total: 1 row(s) affected
I, [2020-06-11T17:18:15.575711 #27148]  INFO -- : Done!
```

### Verbose mode

To get more detailed information about which rows and columns can't be
decrypted, you can pass a `VERBOSE` environment variable:

**Omnibus Installation**

```shell
sudo gitlab-rake gitlab:doctor:secrets VERBOSE=1
```

**Source Installation**

```shell
bundle exec rake gitlab:doctor:secrets RAILS_ENV=production VERBOSE=1
```

**Example verbose output**

<!-- vale gitlab.SentenceSpacing = NO -->
```plaintext
I, [2020-06-11T17:17:54.951815 #27148]  INFO -- : Checking encrypted values in the database
I, [2020-06-11T17:18:12.677708 #27148]  INFO -- : - ApplicationSetting failures: 0
I, [2020-06-11T17:18:12.823692 #27148]  INFO -- : - User failures: 0
[...] other models possibly containing encrypted data
D, [2020-06-11T17:19:53.224344 #27351] DEBUG -- : > Something went wrong for Group[10].runners_token: Validation failed: Route can't be blank
I, [2020-06-11T17:19:53.225178 #27351]  INFO -- : - Group failures: 1
D, [2020-06-11T17:19:53.225267 #27351] DEBUG -- :   - Group[10]: runners_token
I, [2020-06-11T17:18:15.559162 #27148]  INFO -- : - Operations::FeatureFlagsClient failures: 0
I, [2020-06-11T17:18:15.575533 #27148]  INFO -- : - ScimOauthAccessToken failures: 0
I, [2020-06-11T17:18:15.575678 #27148]  INFO -- : Total: 1 row(s) affected
I, [2020-06-11T17:18:15.575711 #27148]  INFO -- : Done!
```
<!-- vale gitlab.SentenceSpacing = YES -->
