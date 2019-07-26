# LDAP Rake Tasks

## Check

The LDAP check Rake task will test the `bind_dn` and `password` credentials
(if configured) and will list a sample of LDAP users. This task is also
executed as part of the `gitlab:check` task, but can run independently
using the command below.

**Omnibus Installation**

```
sudo gitlab-rake gitlab:ldap:check
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:ldap:check RAILS_ENV=production
```

------

By default, the task will return a sample of 100 LDAP users. Change this
limit by passing a number to the check task:

```bash
rake gitlab:ldap:check[50]
```

## Run a Group Sync

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/14735) in [GitLab Starter](https://about.gitlab.com/pricing/) 12.3.

The following task will run a [group sync](../auth/ldap-ee.md#group-sync) immediately. This is valuable
when you'd like to update all configured group memberships against LDAP without
waiting for the next scheduled group sync to be run.

NOTE: **NOTE:**
If you'd like to change the frequency at which a group sync is performed,
[adjust the cron schedule](../auth/ldap-ee.md#adjusting-ldap-group-sync-schedule)
instead.

**Omnibus Installation**

```
sudo gitlab-rake gitlab:ldap:group_sync
```

**Source Installation**

```bash
bundle exec rake gitlab:ldap:group_sync
```

## Rename a provider

If you change the LDAP server ID in `gitlab.yml` or `gitlab.rb` you will need
to update all user identities or users will be unable to sign in. Input the
old and new provider and this task will update all matching identities in the
database.

`old_provider` and `new_provider` are derived from the prefix `ldap` plus the
LDAP server ID from the configuration file. For example, in `gitlab.yml` or
`gitlab.rb` you may see LDAP configuration like this:

```yaml
main:
  label: 'LDAP'
  host: '_your_ldap_server'
  port: 389
  uid: 'sAMAccountName'
  ...
```

`main` is the LDAP server ID. Together, the unique provider is `ldapmain`.

> **Warning**: If you input an incorrect new provider users will be unable
to sign in. If this happens, run the task again with the incorrect provider
as the `old_provider` and the correct provider as the `new_provider`.

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider]
```

**Source Installation**

```bash
bundle exec rake gitlab:ldap:rename_provider[old_provider,new_provider] RAILS_ENV=production
```

### Example

Consider beginning with the default server ID `main` (full provider `ldapmain`).
If we change `main` to `mycompany`, the `new_provider` is `ldapmycompany`.
To rename all user identities run the following command:

```bash
sudo gitlab-rake gitlab:ldap:rename_provider[ldapmain,ldapmycompany]
```

Example output:

```
100 users with provider 'ldapmain' will be updated to 'ldapmycompany'.
If the new provider is incorrect, users will be unable to sign in.
Do you want to continue (yes/no)? yes

User identities were successfully updated
```

### Other options

If you do not specify an `old_provider` and `new_provider` you will be prompted
for them:

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:ldap:rename_provider
```

**Source Installation**

```bash
bundle exec rake gitlab:ldap:rename_provider RAILS_ENV=production
```

**Example output:**

```
What is the old provider? Ex. 'ldapmain': ldapmain
What is the new provider? Ex. 'ldapcustom': ldapmycompany
```

------

This tasks also accepts the `force` environment variable which will skip the
confirmation dialog:

```bash
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider] force=yes
```
